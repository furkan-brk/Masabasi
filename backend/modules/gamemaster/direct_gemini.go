package gamemaster

import (
	"bytes"
	"context"
	"crypto"
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha256"
	"crypto/x509"
	"encoding/base64"
	"encoding/json"
	"encoding/pem"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"strings"
	"time"
)

// DirectGeminiAdapter calls Vertex AI Gemini via raw HTTP with service account auth.
type DirectGeminiAdapter struct {
	projectID  string
	region     string
	model      string
	saKey      *geminiServiceAccountKey
	library    LibrarySource
	httpClient *http.Client
}

type geminiServiceAccountKey struct {
	ClientEmail string `json:"client_email"`
	PrivateKey  string `json:"private_key"`
	TokenURI    string `json:"token_uri"`
	ProjectID   string `json:"project_id"`
}

// NewDirectGeminiAdapter constructs an adapter from a service account JSON string.
func NewDirectGeminiAdapter(saKeyJSON, projectID, region, model string, library LibrarySource) (*DirectGeminiAdapter, error) {
	if saKeyJSON == "" {
		return nil, fmt.Errorf("gamemaster: GCP_SERVICE_ACCOUNT_JSON is required for Vertex AI mode")
	}
	var key geminiServiceAccountKey
	if err := json.Unmarshal([]byte(saKeyJSON), &key); err != nil {
		return nil, fmt.Errorf("gamemaster: parse service account JSON: %w", err)
	}
	if projectID == "" {
		projectID = key.ProjectID
	}
	if region == "" {
		region = "us-central1"
	}
	if model == "" {
		model = "gemini-2.5-flash"
	}
	return &DirectGeminiAdapter{
		projectID:  projectID,
		region:     region,
		model:      model,
		saKey:      &key,
		library:    library,
		httpClient: &http.Client{Timeout: 120 * time.Second},
	}, nil
}

// accessToken exchanges a service-account JWT for a Google OAuth2 access token.
func (a *DirectGeminiAdapter) accessToken(ctx context.Context) (string, error) {
	now := time.Now()
	header, _ := json.Marshal(map[string]string{"alg": "RS256", "typ": "JWT"})
	payload, _ := json.Marshal(map[string]any{
		"iss":   a.saKey.ClientEmail,
		"scope": "https://www.googleapis.com/auth/cloud-platform",
		"aud":   a.saKey.TokenURI,
		"iat":   now.Unix(),
		"exp":   now.Add(time.Hour).Unix(),
	})
	sigInput := base64.RawURLEncoding.EncodeToString(header) + "." + base64.RawURLEncoding.EncodeToString(payload)
	sig, err := rsaSignSHA256(a.saKey.PrivateKey, sigInput)
	if err != nil {
		return "", fmt.Errorf("gamemaster: sign jwt: %w", err)
	}
	tokenURI := a.saKey.TokenURI
	if tokenURI == "" {
		tokenURI = "https://oauth2.googleapis.com/token"
	}
	form := url.Values{
		"grant_type": {"urn:ietf:params:oauth:grant-type:jwt-bearer"},
		"assertion":  {sigInput + "." + sig},
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, tokenURI, strings.NewReader(form.Encode()))
	if err != nil {
		return "", err
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	resp, err := a.httpClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("gamemaster: token request: %w", err)
	}
	defer resp.Body.Close()
	var tok struct {
		AccessToken string `json:"access_token"`
		Error       string `json:"error"`
		ErrorDesc   string `json:"error_description"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&tok); err != nil {
		return "", fmt.Errorf("gamemaster: decode token response: %w", err)
	}
	if tok.Error != "" {
		return "", fmt.Errorf("gamemaster: token error %s: %s", tok.Error, tok.ErrorDesc)
	}
	return tok.AccessToken, nil
}

// --- Gemini API types ---

type geminiContent struct {
	Role  string       `json:"role"`
	Parts []geminiPart `json:"parts"`
}

type geminiPart struct {
	Text             string                  `json:"text,omitempty"`
	FunctionCall     *geminiFunctionCall     `json:"functionCall,omitempty"`
	FunctionResponse *geminiFunctionResponse `json:"functionResponse,omitempty"`
}

type geminiFunctionCall struct {
	Name string         `json:"name"`
	Args map[string]any `json:"args"`
}

type geminiFunctionResponse struct {
	Name     string         `json:"name"`
	Response map[string]any `json:"response"`
}

type geminiRequest struct {
	SystemInstruction *geminiContent  `json:"system_instruction,omitempty"`
	Contents          []geminiContent `json:"contents"`
	Tools             []geminiTool    `json:"tools,omitempty"`
	GenerationConfig  map[string]any  `json:"generation_config,omitempty"`
}

type geminiTool struct {
	FunctionDeclarations []geminiFunctionDecl `json:"function_declarations"`
}

type geminiFunctionDecl struct {
	Name        string         `json:"name"`
	Description string         `json:"description"`
	Parameters  map[string]any `json:"parameters"`
}

type geminiResponse struct {
	Candidates []struct {
		Content      geminiContent `json:"content"`
		FinishReason string        `json:"finishReason"`
	} `json:"candidates"`
}

// searchGamesTool is the function declaration sent to Gemini.
var searchGamesTool = geminiFunctionDecl{
	Name:        "search_library_games",
	Description: "Kulüp kütüphanesindeki oyunları arar ve filtreler. Oyun önerisi yapmadan önce bu araç çağrılmalıdır. Kütüphane dışındaki oyunlar önerilemez.",
	Parameters: map[string]any{
		"type": "OBJECT",
		"properties": map[string]any{
			"query": map[string]any{
				"type":        "STRING",
				"description": "Oyun adında arama (isteğe bağlı)",
			},
			"min_players": map[string]any{
				"type":        "INTEGER",
				"description": "En az bu kadar oyuncuyu destekleyen oyunlar",
			},
			"max_players": map[string]any{
				"type":        "INTEGER",
				"description": "En fazla bu kadar oyuncuyla oynanabilen oyunlar",
			},
			"genres": map[string]any{
				"type":        "STRING",
				"description": "Tür filtresi (örn. strateji, parti, aile)",
			},
			"complexity": map[string]any{
				"type":        "INTEGER",
				"description": "Zorluk seviyesi 1-5 arası (1=çok kolay, 5=çok zor)",
			},
		},
	},
}

const geminiSystemPrompt = `Sen Masabaşı Oyun Kulübü'nün "Oyun Ustası" asistanısın. Üyelerin masa oyunu seçiminde yardımcı oluyorsun.

KURAL: Yalnızca kulüp kütüphanesindeki oyunları önermelisin. Oyun önerisi yapmadan önce search_library_games aracını kullanarak kütüphaneyi sorgula. Kütüphanede olmayan oyunları asla önerme.

Kuralları açıklayabilir, oyun önerebilir, takım büyüklüğüne ve süre tercihlerine göre tavsiye verebilirsin. Her zaman Türkçe yanıt ver. Kural kitapçığının yerini tutamayacağını hatırlatabilirsin.`

// Chat implements the Client interface with a Gemini function-calling loop.
func (a *DirectGeminiAdapter) Chat(ctx context.Context, history []Message) (*Reply, error) {
	token, err := a.accessToken(ctx)
	if err != nil {
		log.Printf("gamemaster: accessToken error: %v", err)
		return &Reply{Text: "Oyun Ustası kimlik doğrulaması başarısız. Lütfen yönetici ile iletişime geçin."}, nil
	}

	contents := make([]geminiContent, 0, len(history))
	for _, m := range history {
		role := m.Role
		if role == "assistant" {
			role = "model"
		}
		contents = append(contents, geminiContent{
			Role:  role,
			Parts: []geminiPart{{Text: m.Content}},
		})
	}

	endpoint := fmt.Sprintf(
		"https://%s-aiplatform.googleapis.com/v1/projects/%s/locations/%s/publishers/google/models/%s:generateContent",
		a.region, a.projectID, a.region, a.model,
	)

	// Tool-call loop: max 5 turns to prevent infinite loops.
	for turn := 0; turn < 5; turn++ {
		body, _ := json.Marshal(geminiRequest{
			SystemInstruction: &geminiContent{Parts: []geminiPart{{Text: geminiSystemPrompt}}},
			Contents:          contents,
			Tools:             []geminiTool{{FunctionDeclarations: []geminiFunctionDecl{searchGamesTool}}},
			GenerationConfig:  map[string]any{"maxOutputTokens": 8192},
		})

		req, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint, bytes.NewReader(body))
		if err != nil {
			return nil, fmt.Errorf("gamemaster: build request: %w", err)
		}
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+token)

		resp, err := a.httpClient.Do(req)
		if err != nil {
			return &Reply{Text: "Oyun Ustası'na şu an ulaşılamıyor. Lütfen birazdan tekrar deneyin."}, nil
		}

		if resp.StatusCode != http.StatusOK {
			b, _ := io.ReadAll(resp.Body)
			resp.Body.Close()
			return &Reply{Text: fmt.Sprintf("Oyun Ustası yanıt veremiyor (%d): %s", resp.StatusCode, string(b))}, nil
		}

		var result geminiResponse
		if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
			resp.Body.Close()
			return &Reply{Text: "Oyun Ustası yanıtı çözümlenemedi. Lütfen tekrar deneyin."}, nil
		}
		resp.Body.Close()

		if len(result.Candidates) == 0 || len(result.Candidates[0].Content.Parts) == 0 {
			return &Reply{Text: "Oyun Ustası boş yanıt döndürdü. Lütfen tekrar deneyin."}, nil
		}

		candidate := result.Candidates[0]

		// Check for function call in any part.
		var funcCall *geminiFunctionCall
		for _, p := range candidate.Content.Parts {
			if p.FunctionCall != nil {
				funcCall = p.FunctionCall
				break
			}
		}

		if funcCall != nil {
			// Execute the tool and append both the model's call and our response.
			toolResult := a.executeSearchGames(funcCall.Args)
			contents = append(contents,
				candidate.Content,
				geminiContent{
					Role: "user",
					Parts: []geminiPart{{
						FunctionResponse: &geminiFunctionResponse{
							Name:     funcCall.Name,
							Response: toolResult,
						},
					}},
				},
			)
			continue
		}

		// Text response — return it.
		if r := candidate.FinishReason; r != "" && r != "STOP" {
			log.Printf("gamemaster: finishReason=%s", r)
		}
		return &Reply{Text: candidate.Content.Parts[0].Text}, nil
	}

	return &Reply{Text: "Oyun Ustası yanıt üretemedi. Lütfen tekrar deneyin."}, nil
}

// executeSearchGames runs the library query and formats the result for Gemini.
func (a *DirectGeminiAdapter) executeSearchGames(args map[string]any) map[string]any {
	f := LibraryFilter{}
	if q, ok := args["query"].(string); ok {
		f.Query = q
	}
	if v, ok := args["min_players"].(float64); ok {
		n := int(v)
		f.MinPlayers = &n
	}
	if v, ok := args["max_players"].(float64); ok {
		n := int(v)
		f.MaxPlayers = &n
	}
	if g, ok := args["genres"].(string); ok {
		f.Genres = g
	}
	if v, ok := args["complexity"].(float64); ok {
		n := int(v)
		f.Complexity = &n
	}

	games, err := a.library.SearchGames(f)
	if err != nil || len(games) == 0 {
		return map[string]any{"games": []any{}, "message": "Filtreye uyan oyun bulunamadı."}
	}

	result := make([]map[string]any, 0, len(games))
	for _, g := range games {
		result = append(result, map[string]any{
			"title":        g.Title,
			"min_players":  g.MinPlayers,
			"max_players":  g.MaxPlayers,
			"duration_min": g.DurationMin,
			"complexity":   g.Complexity,
			"genres":       g.Genres,
		})
	}
	return map[string]any{"games": result}
}

// rsaSignSHA256 signs data with an RSA private key using PKCS#1 v1.5 + SHA-256.
func rsaSignSHA256(pemKey, data string) (string, error) {
	block, _ := pem.Decode([]byte(pemKey))
	if block == nil {
		return "", fmt.Errorf("no PEM block found in private key")
	}
	var key *rsa.PrivateKey
	if parsed, err := x509.ParsePKCS8PrivateKey(block.Bytes); err == nil {
		var ok bool
		if key, ok = parsed.(*rsa.PrivateKey); !ok {
			return "", fmt.Errorf("service account key is not RSA")
		}
	} else {
		var err2 error
		if key, err2 = x509.ParsePKCS1PrivateKey(block.Bytes); err2 != nil {
			return "", fmt.Errorf("parse private key (pkcs8: %v; pkcs1: %v)", err, err2)
		}
	}
	h := sha256.New()
	h.Write([]byte(data))
	sig, err := rsa.SignPKCS1v15(rand.Reader, key, crypto.SHA256, h.Sum(nil))
	if err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(sig), nil
}
