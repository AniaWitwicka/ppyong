package service

import "math"

const minEaseFactor = 1.3

// Calculate runs one SM-2 iteration.
// Returns the updated ease_factor and interval_days to schedule next review.
// knewIt=true → quality 5 (easy); knewIt=false → quality 1 (again).
func SRSCalculate(easeFactor float64, intervalDays, repetitions int, knewIt bool) (newEaseFactor float64, newIntervalDays int) {
	quality := 1
	if knewIt {
		quality = 5
	}

	newEaseFactor = easeFactor + 0.1 - float64(5-quality)*(0.08+float64(5-quality)*0.02)
	if newEaseFactor < minEaseFactor {
		newEaseFactor = minEaseFactor
	}

	if !knewIt {
		return newEaseFactor, 1
	}

	switch repetitions {
	case 0:
		newIntervalDays = 1
	case 1:
		newIntervalDays = 6
	default:
		newIntervalDays = int(math.Round(float64(intervalDays) * easeFactor))
	}
	return newEaseFactor, newIntervalDays
}
