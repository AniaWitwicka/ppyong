package service

import (
	"bufio"
	"strings"

	"github.com/yourname/koreanapp-backend/internal/model"
)

const maxImportCards = 200

// ParseCardText auto-detects the delimiter (|, tab, comma) and parses up to 200 cards.
// Column order: Korean · Translation · Romanisation (romanisation is optional).
func ParseCardText(raw string) model.ParseResult {
	sep, format := detectDelimiter(raw)

	var cards []model.ParsedCard
	scanner := bufio.NewScanner(strings.NewReader(raw))
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" {
			continue
		}
		parts := strings.Split(line, sep)
		for i := range parts {
			parts[i] = strings.TrimSpace(parts[i])
		}
		if len(parts) < 2 || parts[0] == "" || parts[1] == "" {
			continue
		}
		card := model.ParsedCard{Korean: parts[0], Translation: parts[1]}
		if len(parts) >= 3 {
			card.Romanisation = parts[2]
		}
		cards = append(cards, card)
		if len(cards) >= maxImportCards {
			break
		}
	}

	if cards == nil {
		cards = []model.ParsedCard{}
	}
	return model.ParseResult{
		DetectedFormat: format,
		ParsedCards:    cards,
		TotalCount:     len(cards),
	}
}

// detectDelimiter returns the delimiter and its display name by checking the first non-empty line.
func detectDelimiter(raw string) (sep, format string) {
	candidates := []struct{ sep, name string }{
		{"|", "ko|en|romaja"},
		{"\t", "ko · en · romaja (tab)"},
		{",", "ko,en,romaja"},
	}

	scanner := bufio.NewScanner(strings.NewReader(raw))
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" {
			continue
		}
		best := 0
		sep = "|"
		format = "ko|en|romaja"
		for _, c := range candidates {
			n := len(strings.Split(line, c.sep))
			if n > best {
				best = n
				sep = c.sep
				format = c.name
			}
		}
		return
	}
	return "|", "ko|en|romaja"
}
