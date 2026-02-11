package services

import (
	"math"
	"testing"
)

func TestPercentileCalculator_Calculate_EmptyValues(t *testing.T) {
	calc := NewPercentileCalculator()
	got := calc.Calculate([]int64{}, 50)
	if got != 0 {
		t.Errorf("Calculate([]int64{}, 50) = %v; want 0", got)
	}
}

func TestPercentileCalculator_Calculate_SingleValue(t *testing.T) {
	calc := NewPercentileCalculator()
	got := calc.Calculate([]int64{100}, 50)
	if got != 100 {
		t.Errorf("Calculate([]int64{100}, 50) = %v; want 100", got)
	}
}

func TestPercentileCalculator_Calculate_P50(t *testing.T) {
	calc := NewPercentileCalculator()
	// 1,2,3,4,5 -> p50 is median = 3
	values := []int64{5, 1, 4, 2, 3}
	got := calc.Calculate(values, 50)
	if got != 3 {
		t.Errorf("Calculate(1..5, 50) = %v; want 3", got)
	}
}

func TestPercentileCalculator_Calculate_P95(t *testing.T) {
	calc := NewPercentileCalculator()
	// 1..100: p95 index ≈ 94.05, interpolated
	values := make([]int64, 100)
	for i := range values {
		values[i] = int64(i + 1)
	}
	got := calc.Calculate(values, 95)
	// index = 0.95 * 99 = 94.05 -> between 95 and 96
	if got < 94 || got > 97 {
		t.Errorf("Calculate(1..100, 95) = %v; want roughly 95-96", got)
	}
}

func TestPercentileCalculator_Calculate_P99(t *testing.T) {
	calc := NewPercentileCalculator()
	values := make([]int64, 100)
	for i := range values {
		values[i] = int64(i + 1)
	}
	got := calc.Calculate(values, 99)
	if got < 98 || got > 100 {
		t.Errorf("Calculate(1..100, 99) = %v; want roughly 99-100", got)
	}
}

func TestPercentileCalculator_Calculate_DoesNotMutateInput(t *testing.T) {
	calc := NewPercentileCalculator()
	values := []int64{5, 3, 1, 4, 2}
	orig := make([]int64, len(values))
	copy(orig, values)
	_ = calc.Calculate(values, 50)
	for i := range values {
		if values[i] != orig[i] {
			t.Errorf("Calculate mutated input: got %v, want %v", values, orig)
			break
		}
	}
}

func TestPercentileCalculator_CalculatePercentiles_Empty(t *testing.T) {
	calc := NewPercentileCalculator()
	got := calc.CalculatePercentiles([]int64{}, []float64{50, 95, 99})
	if len(got) != 3 {
		t.Errorf("expected 3 keys, got %v", got)
	}
	for k, v := range got {
		if v != 0 {
			t.Errorf("CalculatePercentiles([], ...)[%s] = %v; want 0", k, v)
		}
	}
}

func TestPercentileCalculator_CalculatePercentiles_Multiple(t *testing.T) {
	calc := NewPercentileCalculator()
	values := make([]int64, 100)
	for i := range values {
		values[i] = int64(i + 1)
	}
	got := calc.CalculatePercentiles(values, []float64{50, 95, 99})
	if got["p50"] != 50.5 {
		t.Errorf("p50 = %v; want 50.5", got["p50"])
	}
	if _, ok := got["p95"]; !ok {
		t.Error("expected p95 key")
	}
	if _, ok := got["p99"]; !ok {
		t.Error("expected p99 key")
	}
}

func TestPercentileCalculator_CalculatePercentiles_CustomPercentile(t *testing.T) {
	calc := NewPercentileCalculator()
	values := []int64{10, 20, 30, 40, 50}
	got := calc.CalculatePercentiles(values, []float64{75})
	// index = 0.75 * (5-1) = 3, so p75 = 40
	if math.Abs(got["p75"]-40) > 1 {
		t.Errorf("p75 = %v; want 40", got["p75"])
	}
}
