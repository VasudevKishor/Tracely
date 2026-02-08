package services

import (
	"fmt"
	"math"
	"sort"
)

type PercentileCalculator struct{}

func NewPercentileCalculator() *PercentileCalculator {
	return &PercentileCalculator{}
}

// Calculate calculates percentile from sorted values
func (p *PercentileCalculator) Calculate(values []int64, percentile float64) float64 {
	if len(values) == 0 {
		return 0
	}

	// Sort values
	sorted := make([]int64, len(values))
	copy(sorted, values)
	sort.Slice(sorted, func(i, j int) bool {
		return sorted[i] < sorted[j]
	})

	// Calculate percentile index
	index := (percentile / 100.0) * float64(len(sorted)-1)
	lower := int(math.Floor(index))
	upper := int(math.Ceil(index))

	if lower == upper {
		return float64(sorted[lower])
	}

	// Linear interpolation
	weight := index - float64(lower)
	return float64(sorted[lower])*(1-weight) + float64(sorted[upper])*weight
}

// CalculatePercentiles calculates multiple percentiles at once
func (p *PercentileCalculator) CalculatePercentiles(values []int64, percentiles []float64) map[string]float64 {
	results := make(map[string]float64)

	for _, pct := range percentiles {
		key := ""
		switch pct {
		case 50:
			key = "p50"
		case 95:
			key = "p95"
		case 99:
			key = "p99"
		default:
			key = fmt.Sprintf("p%.0f", pct)
		}
		results[key] = p.Calculate(values, pct)
	}

	return results
}
