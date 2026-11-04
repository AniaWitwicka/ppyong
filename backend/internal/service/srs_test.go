package service

import "testing"

func TestSRSEarlyInterval(t *testing.T) {
	cases := []struct {
		name          string
		interval, age int
		ease          float64
		want          int
		grows         bool
	}{
		{"same day again: no change", 6, 0, 2.6, 6, false},
		{"one day after a 6-day step: too early", 6, 1, 2.6, 6, false},
		{"three days into a 6-day step: earns 8", 6, 3, 2.6, 8, true},
		{"missed today, passed today: stays tomorrow", 1, 0, 1.96, 1, false},
	}
	for _, c := range cases {
		got, grows := SRSEarlyInterval(c.interval, c.age, c.ease)
		if got != c.want || grows != c.grows {
			t.Errorf("%s: got (%d, %v), want (%d, %v)", c.name, got, grows, c.want, c.grows)
		}
	}
}

func TestSRSCalculateUnchanged(t *testing.T) {
	// The normal steps stay 1 → 6 → interval × ease.
	if _, i := SRSCalculate(2.5, 1, 0, true); i != 1 {
		t.Errorf("first pass: %d", i)
	}
	if _, i := SRSCalculate(2.6, 1, 1, true); i != 6 {
		t.Errorf("second pass: %d", i)
	}
	if _, i := SRSCalculate(2.7, 6, 2, true); i != 16 {
		t.Errorf("third pass: %d", i)
	}
	if _, i := SRSCalculate(2.7, 16, 3, false); i != 1 {
		t.Errorf("again: %d", i)
	}
}
