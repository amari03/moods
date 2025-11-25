// internal/quotes/quotes.go
package quotes

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"time"
)

// Quote defines the structure of the quote object from the Zen Quotes API.
// We use struct tags to map the JSON keys 'q' and 'a' to our Go fields.
type Quote struct {
	Text   string `json:"q"`
	Author string `json:"a"`
}

// Client is a client for the Zen Quotes API.
type Client struct {
	httpClient *http.Client
}

// NewClient creates a new Zen Quotes client.
func NewClient() *Client {
	return &Client{
		httpClient: &http.Client{
			Timeout: 5 * time.Second, // It's crucial to set a timeout.
		},
	}
}

// GetRandomQuote fetches a single random quote.
func (c *Client) GetRandomQuote(ctx context.Context) (*Quote, error) {
	// The API URL for a random quote.
	url := "https://zenquotes.io/api/random"

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return nil, err
	}

	res, err := c.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer res.Body.Close()

	if res.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("zen quotes api returned non-200 status: %d", res.StatusCode)
	}

	// The API returns an array of quotes, even for a single random one.
	// So we must decode into a slice of Quote structs.
	var quotes []Quote

	if err := json.NewDecoder(res.Body).Decode(&quotes); err != nil {
		return nil, err
	}

	// If for some reason the array is empty, return an error.
	if len(quotes) == 0 {
		return nil, fmt.Errorf("received an empty quote list from api")
	}

	// Return a pointer to the first (and only) quote in the slice.
	return &quotes[0], nil
}