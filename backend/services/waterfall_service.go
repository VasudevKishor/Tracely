package services

import (
	"backend/models"
	"encoding/json"
	"fmt"
	"sort"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type WaterfallNode struct {
	SpanID      uuid.UUID         `json:"span_id"`
	Name        string            `json:"name"`
	ServiceName string            `json:"service_name"`
	StartTime   time.Time         `json:"start_time"`
	EndTime     time.Time         `json:"end_time"`
	Duration    int64             `json:"duration_ms"`
	Offset      int64             `json:"offset_ms"` // Offset from trace start
	Depth       int               `json:"depth"`
	Children    []WaterfallNode   `json:"children,omitempty"`
	Tags        map[string]string `json:"tags,omitempty"`
}

type WaterfallService struct {
	db *gorm.DB
}

func NewWaterfallService(db *gorm.DB) *WaterfallService {
	return &WaterfallService{db: db}
}

// GenerateWaterfall creates waterfall chart data from trace
func (s *WaterfallService) GenerateWaterfall(traceID uuid.UUID) (*WaterfallNode, error) {
	var trace models.Trace
	if err := s.db.Preload("Spans").First(&trace, traceID).Error; err != nil {
		return nil, err
	}

	// Build span map
	spanMap := make(map[uuid.UUID]*models.Span)
	for i := range trace.Spans {
		spanMap[trace.Spans[i].ID] = &trace.Spans[i]
	}

	// Find root span
	var rootSpan *models.Span
	for _, span := range trace.Spans {
		if span.ParentSpanID == nil {
			rootSpan = &span
			break
		}
	}

	if rootSpan == nil {
		return nil, fmt.Errorf("no root span found")
	}

	// Build waterfall tree
	root := s.buildWaterfallNode(rootSpan, spanMap, trace.StartTime, 0)
	return root, nil
}

func (s *WaterfallService) buildWaterfallNode(span *models.Span, spanMap map[uuid.UUID]*models.Span, traceStart time.Time, depth int) *WaterfallNode {
	offset := span.StartTime.Sub(traceStart).Milliseconds()

	node := &WaterfallNode{
		SpanID:      span.ID,
		Name:        span.OperationName,
		ServiceName: span.ServiceName,
		StartTime:   span.StartTime,
		EndTime:     span.StartTime.Add(time.Duration(span.DurationMs) * time.Millisecond),
		Duration:    int64(span.DurationMs),
		Offset:      offset,
		Depth:       depth,
		Children:    []WaterfallNode{},
	}

	// Parse tags if present
	if span.Tags != "" {
		var tags map[string]string
		json.Unmarshal([]byte(span.Tags), &tags)
		node.Tags = tags
	}

	// Find and add children
	for _, childSpan := range spanMap {
		if childSpan.ParentSpanID != nil && *childSpan.ParentSpanID == span.ID {
			child := s.buildWaterfallNode(childSpan, spanMap, traceStart, depth+1)
			node.Children = append(node.Children, *child)
		}
	}

	// Sort children by start time
	sort.Slice(node.Children, func(i, j int) bool {
		return node.Children[i].StartTime.Before(node.Children[j].StartTime)
	})

	return node
}
