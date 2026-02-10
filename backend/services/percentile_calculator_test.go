package services

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestPercentileCalculator_Calculate(t *testing.T) {
	calc := NewPercentileCalculator()

	// Test dataset: 1 to 10
	values := []int64{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}

	tests := []struct {
		name       string
		percentile float64
		expected   float64
	}{
		{"P50 (Median)", 50, 5.5},
		{"P0 (Min)", 0, 1.0},
		{"P100 (Max)", 100, 10.0},
		{"P95", 95, 9.55},
		{"P99", 99, 9.91},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := calc.Calculate(values, tt.percentile)
			// InDelta checks if the values are within 0.01 of each other
			assert.InDelta(t, tt.expected, result, 0.01)
		})
	}
}

func TestPercentileCalculator_EmptySlice(t *testing.T) {
	calc := NewPercentileCalculator()
	result := calc.Calculate([]int64{}, 95)
	assert.Equal(t, 0.0, result)
}

func TestPercentileCalculator_UnsortedInput(t *testing.T) {
	calc := NewPercentileCalculator()
	// Input is deliberately unsorted
	values := []int64{10, 1, 9, 2, 8, 3, 7, 4, 6, 5}

	result := calc.Calculate(values, 50)
	assert.Equal(t, 5.5, result, "Should sort values before calculating")
}

func TestPercentileCalculator_CalculatePercentiles(t *testing.T) {
	calc := NewPercentileCalculator()
	values := []int64{100, 200, 300, 400, 500}
	pcts := []float64{50, 95, 99}

	results := calc.CalculatePercentiles(values, pcts)

	assert.Contains(t, results, "p50")
	assert.Contains(t, results, "p95")
	assert.Contains(t, results, "p99")

	// P50 of [100, 200, 300, 400, 500] is 300
	assert.Equal(t, 300.0, results["p50"])
}
