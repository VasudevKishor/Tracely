package integrations

import (
	"encoding/json"
	"fmt"
	"net/http"
	"time"
)

type PrometheusIntegration struct {
	baseURL string
	client  *http.Client
}

func NewPrometheusIntegration(baseURL string) *PrometheusIntegration {
	return &PrometheusIntegration{
		baseURL: baseURL,
		client:  &http.Client{Timeout: 10 * time.Second},
	}
}

// QueryRange queries Prometheus for metrics in time range
func (p *PrometheusIntegration) QueryRange(query string, start, end time.Time, step string) ([]MetricPoint, error) {
	url := fmt.Sprintf("%s/api/v1/query_range?query=%s&start=%d&end=%d&step=%s",
		p.baseURL, query, start.Unix(), end.Unix(), step)

	resp, err := p.client.Get(url)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var result PrometheusResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}

	points := []MetricPoint{}
	if len(result.Data.Result) > 0 {
		for _, val := range result.Data.Result[0].Values {
			timestamp := val[0].(float64)
			value := val[1].(string)

			points = append(points, MetricPoint{
				Timestamp: time.Unix(int64(timestamp), 0),
				Value:     value,
			})
		}
	}

	return points, nil
}

type MetricPoint struct {
	Timestamp time.Time
	Value     string
}

type PrometheusResponse struct {
	Status string `json:"status"`
	Data   struct {
		ResultType string `json:"resultType"`
		Result     []struct {
			Metric map[string]string `json:"metric"`
			Values [][]interface{}   `json:"values"`
		} `json:"result"`
	} `json:"data"`
}

// CorrelateWithTrace correlates metrics with trace timeline
func (p *PrometheusIntegration) CorrelateWithTrace(traceID string, start, end time.Time) (map[string][]MetricPoint, error) {
	metrics := map[string][]MetricPoint{}

	// Query common metrics
	queries := map[string]string{
		"cpu":    fmt.Sprintf(`container_cpu_usage_seconds_total{trace_id="%s"}`, traceID),
		"memory": fmt.Sprintf(`container_memory_usage_bytes{trace_id="%s"}`, traceID),
		"errors": fmt.Sprintf(`http_requests_total{trace_id="%s",status=~"5.."}`, traceID),
	}

	for name, query := range queries {
		points, err := p.QueryRange(query, start, end, "15s")
		if err == nil {
			metrics[name] = points
		}
	}

	return metrics, nil
}
