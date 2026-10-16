package gamemaster

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

const (
	claudeEndpoint = "https://api.anthropic.com/v1/messages"
	claudeModel    = "claude-haiku-4-5-20251001"
	claudeVersion  = "2023-06-01"
	claudeMaxToks  = 1024
)

const systemPrompt = `Sen Masabaşı Oyun Kulübü'nün "Oyun Ustası" asistanısın. Üyelerin masa oyunu seçiminde
yardımcı oluyorsun. Kuralları açıklayabilir, oyun önerebilir, takım büyüklüğüne ve
süre tercihlerine göre tavsiye verebilirsin. Her zaman Türkçe yanıt ver.
Tavsiyelerin kulüp kütüphanesindeki oyunlara öncelik versin.
Kural kitapçığının yerini tutamayacağını hatırlatabilirsin.`

// DirectClaudeAdapter calls the Anthropic Messages API over raw HTTP.
type DirectClaudeAdapter struct {
	apiKey string
	client *http.Client
}

// NewDirectClaudeAdapter constructs an adapter for the given API key.
func NewDirectClaudeAdapter(apiKey string) *DirectClaudeAdapter {
	return &DirectClaudeAdapter{
		apiKey: apiKey,
		client: &http.Client{Timeout: 60 * time.Second},
	}
}

type claudeRequest struct {
	Model     string          `json:"model"`
	MaxTokens int             `json:"max_tokens"`
	System    string          `json:"system"`
	Messages  []claudeMessage `json:"messages"`
}

type claudeMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type claudeResponse struct {
	Content []struct {
		Type string `json:"type"`
		Text string `json:"text"`
	} `json:"content"`
}

// Chat sends the conversation history to Claude and returns the reply.
func (a *DirectClaudeAdapter) Chat(ctx context.Context, history []Message) (*Reply, error) {
	if a.apiKey == "" {
		return &Reply{Text: "API anahtarı yapılandırılmamış. Lütfen yönetici ile iletişime geçin."}, nil
	}

	msgs := make([]claudeMessage, 0, len(history))
	for _, m := range history {
		msgs = append(msgs, claudeMessage{Role: m.Role, Content: m.Content})
	}

	body, err := json.Marshal(claudeRequest{
		Model:     claudeModel,
		MaxTokens: claudeMaxToks,
		System:    systemPrompt,
		Messages:  msgs,
	})
	if err != nil {
		return nil, fmt.Errorf("gamemaster: marshal request: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, claudeEndpoint, bytes.NewReader(body))
	if err != nil {
		return nil, fmt.Errorf("gamemaster: build request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("x-api-key", a.apiKey)
	req.Header.Set("anthropic-version", claudeVersion)

	resp, err := a.client.Do(req)
	if err != nil {
		return &Reply{Text: "Oyun Ustası'na şu an ulaşılamıyor. Lütfen birazdan tekrar deneyin."}, nil
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		_, _ = io.Copy(io.Discard, resp.Body)
		return &Reply{Text: "Oyun Ustası şu an yanıt veremiyor. Lütfen birazdan tekrar deneyin."}, nil
	}

	var result claudeResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return &Reply{Text: "Oyun Ustası'nın yanıtı çözümlenemedi. Lütfen tekrar deneyin."}, nil
	}

	if len(result.Content) == 0 {
		return &Reply{Text: "Oyun Ustası boş bir yanıt döndürdü. Lütfen tekrar deneyin."}, nil
	}

	return &Reply{Text: result.Content[0].Text}, nil
}
