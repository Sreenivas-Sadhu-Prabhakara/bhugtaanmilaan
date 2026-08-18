package backend

import (
	"encoding/json"
	"fmt"
)

// Payment is one sale's tender, logged as it happens so the day's channel totals
// are an independent record — not back-derived from the closing counts.
type Payment struct {
	Channel string  `json:"channel"` // cash | upi | card
	Amount  float64 `json:"amount"`
}

var validChannels = map[string]bool{"cash": true, "upi": true, "card": true}

// Validate reports whether the Payment is well formed.
func (p Payment) Validate() error {
	if !validChannels[p.Channel] {
		return fmt.Errorf("channel must be cash, upi or card")
	}
	if p.Amount <= 0 {
		return fmt.Errorf("amount must be positive")
	}
	return nil
}

// Summary totals logged sales per channel.
type Summary struct {
	Cash  float64 `json:"cash"`
	UPI   float64 `json:"upi"`
	Card  float64 `json:"card"`
	Total float64 `json:"total"`
}

// Summarize sums logged payments by channel.
func Summarize(records []Record) Summary {
	var s Summary
	for _, r := range records {
		switch r.Label {
		case "cash":
			s.Cash += r.Headline
		case "upi":
			s.UPI += r.Headline
		case "card":
			s.Card += r.Headline
		}
	}
	s.Total = s.Cash + s.UPI + s.Card
	return s
}

// Gaps compares logged channel totals against the closing counts. A non-zero gap
// points at the specific channel where money went missing or was mis-tendered.
type Gaps struct {
	Cash float64 `json:"cash"`
	UPI  float64 `json:"upi"`
	Card float64 `json:"card"`
}

// ReconcileGaps returns counted minus logged per channel.
func ReconcileGaps(logged Summary, countedCash, countedUPI, countedCard float64) Gaps {
	return Gaps{
		Cash: countedCash - logged.Cash,
		UPI:  countedUPI - logged.UPI,
		Card: countedCard - logged.Card,
	}
}

// parseEntry decodes+validates a payment; headline is the amount, label the channel.
func parseEntry(raw []byte) (float64, string, error) {
	var p Payment
	if err := json.Unmarshal(raw, &p); err != nil {
		return 0, "", fmt.Errorf("invalid json")
	}
	if err := p.Validate(); err != nil {
		return 0, "", err
	}
	return p.Amount, p.Channel, nil
}
