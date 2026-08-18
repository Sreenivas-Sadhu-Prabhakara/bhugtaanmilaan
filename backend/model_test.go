package backend

import (
	"math"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

type memStore struct{ items []Record }

func (m *memStore) Save(r Record) (Record, error) {
	r.ID = int64(len(m.items) + 1)
	m.items = append([]Record{r}, m.items...)
	return r, nil
}
func (m *memStore) List(limit int) ([]Record, error) { return m.items, nil }

func TestSummarizeByChannel(t *testing.T) {
	recs := []Record{
		{Headline: 100, Label: "cash"}, {Headline: 250, Label: "upi"},
		{Headline: 50, Label: "cash"}, {Headline: 400, Label: "card"},
	}
	s := Summarize(recs)
	if s.Cash != 150 || s.UPI != 250 || s.Card != 400 || s.Total != 800 {
		t.Fatalf("summary wrong: %+v", s)
	}
}

func TestReconcileGaps(t *testing.T) {
	logged := Summary{Cash: 150, UPI: 250, Card: 400}
	g := ReconcileGaps(logged, 130, 250, 400) // ₹20 cash short
	if math.Abs(g.Cash+20) > 1e-9 || g.UPI != 0 || g.Card != 0 {
		t.Fatalf("gaps wrong: %+v", g)
	}
}

func TestValidateAndLog(t *testing.T) {
	if err := (Payment{Channel: "gpay", Amount: 10}).Validate(); err == nil {
		t.Fatal("bad channel accepted")
	}
	srv := NewServer(&memStore{})
	rec := httptest.NewRecorder()
	srv.ServeHTTP(rec, httptest.NewRequest(http.MethodPost, "/log", strings.NewReader(`{"channel":"upi","amount":250}`)))
	if rec.Code != http.StatusCreated {
		t.Fatalf("log %d", rec.Code)
	}
}
