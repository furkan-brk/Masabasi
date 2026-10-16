// Package gamemaster provides the AI "Oyun Ustası" board-game assistant.
package gamemaster

import "context"

// Message is a single turn in the conversation.
type Message struct {
	Role    string `json:"role"`    // "user" or "assistant"
	Content string `json:"content"` // turn text
}

// SuggestedGame is a game the Oyun Ustası recommends.
type SuggestedGame struct {
	Title       string `json:"title"`
	Reason      string `json:"reason"`
	MinPlayers  int    `json:"minPlayers"`
	MaxPlayers  int    `json:"maxPlayers"`
	DurationMin int    `json:"durationMin"`
}

// Reply is the model's response.
type Reply struct {
	Text           string          `json:"text"`
	SuggestedGames []SuggestedGame `json:"suggestedGames"`
}

// LibraryGame is a game record passed as tool result.
type LibraryGame struct {
	Title       string
	MinPlayers  int
	MaxPlayers  int
	DurationMin int
	Complexity  int
	Genres      string
}

// LibraryFilter carries optional filters for the search_library_games tool.
type LibraryFilter struct {
	Query      string `json:"query,omitempty"`
	MinPlayers *int   `json:"min_players,omitempty"`
	MaxPlayers *int   `json:"max_players,omitempty"`
	Genres     string `json:"genres,omitempty"`
	Complexity *int   `json:"complexity,omitempty"`
}

// LibrarySource is implemented by the library adapter in cmd/server/main.go.
type LibrarySource interface {
	SearchGames(f LibraryFilter) ([]LibraryGame, error)
}

// Client is the abstraction over AI providers.
type Client interface {
	Chat(ctx context.Context, history []Message) (*Reply, error)
}
