package services

import (
	"sync"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type LoadTest struct {
	ID              uuid.UUID `gorm:"type:uuid;primary_key"`
	WorkspaceID     uuid.UUID `gorm:"type:uuid;not null"`
	Name            string    `gorm:"not null"`
	RequestID       uuid.UUID `gorm:"type:uuid;not null"`
	Concurrency     int       `gorm:"not null"`
	TotalRequests   int       `gorm:"not null"`
	RampUpSeconds   int       `gorm:"default:0"`
	Duration        int       // seconds
	Status          string    `gorm:"default:'pending'"` // pending, running, completed, failed
	SuccessCount    int       `gorm:"default:0"`
	FailureCount    int       `gorm:"default:0"`
	AvgResponseTime float64
	P95ResponseTime float64
	P99ResponseTime float64
	CreatedAt       time.Time
	StartedAt       *time.Time
	CompletedAt     *time.Time
}

type LoadTestService struct {
	db             *gorm.DB
	requestService *RequestService
}

func NewLoadTestService(db *gorm.DB) *LoadTestService {
	return &LoadTestService{
		db:             db,
		requestService: NewRequestService(db),
	}
}

func (s *LoadTestService) CreateLoadTest(workspaceID, requestID, userID uuid.UUID, name string, concurrency, totalRequests, rampUp int) (*LoadTest, error) {
	test := LoadTest{
		ID:            uuid.New(),
		WorkspaceID:   workspaceID,
		Name:          name,
		RequestID:     requestID,
		Concurrency:   concurrency,
		TotalRequests: totalRequests,
		RampUpSeconds: rampUp,
		Status:        "pending",
	}

	if err := s.db.Create(&test).Error; err != nil {
		return nil, err
	}

	// Start load test in background
	go s.executeLoadTest(test.ID, userID)

	return &test, nil
}

func (s *LoadTestService) executeLoadTest(testID, userID uuid.UUID) {
	var test LoadTest
	if err := s.db.First(&test, testID).Error; err != nil {
		return
	}

	now := time.Now()
	s.db.Model(&test).Updates(map[string]interface{}{
		"status":     "running",
		"started_at": now,
	})

	var wg sync.WaitGroup
	var mu sync.Mutex
	responseTimes := []int64{}
	successCount := 0
	failureCount := 0

	// Calculate requests per worker
	requestsPerWorker := test.TotalRequests / test.Concurrency

	for i := 0; i < test.Concurrency; i++ {
		wg.Add(1)

		// Ramp-up delay
		if test.RampUpSeconds > 0 {
			delay := time.Duration(i*test.RampUpSeconds/test.Concurrency) * time.Second
			time.Sleep(delay)
		}

		go func(workerID int) {
			defer wg.Done()

			for j := 0; j < requestsPerWorker; j++ {
				execution, err := s.requestService.Execute(test.RequestID, userID, "", nil, uuid.New(), nil, nil)

				mu.Lock()
				if err != nil || execution.StatusCode >= 400 {
					failureCount++
				} else {
					successCount++
					responseTimes = append(responseTimes, execution.ResponseTimeMs)
				}
				mu.Unlock()
			}
		}(i)
	}

	wg.Wait()

	// Calculate statistics
	var avgResponseTime, p95, p99 float64
	if len(responseTimes) > 0 {
		sum := int64(0)
		for _, rt := range responseTimes {
			sum += rt
		}
		avgResponseTime = float64(sum) / float64(len(responseTimes))

		// Simple percentile calculation (would use proper algorithm in production)
		p95Index := int(float64(len(responseTimes)) * 0.95)
		p99Index := int(float64(len(responseTimes)) * 0.99)
		if p95Index < len(responseTimes) {
			p95 = float64(responseTimes[p95Index])
		}
		if p99Index < len(responseTimes) {
			p99 = float64(responseTimes[p99Index])
		}
	}

	completedAt := time.Now()
	s.db.Model(&test).Updates(map[string]interface{}{
		"status":            "completed",
		"completed_at":      completedAt,
		"success_count":     successCount,
		"failure_count":     failureCount,
		"avg_response_time": avgResponseTime,
		"p95_response_time": p95,
		"p99_response_time": p99,
	})
}
