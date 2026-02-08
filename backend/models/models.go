package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/datatypes"
	"gorm.io/gorm"
)

// User represents a user account
type User struct {
	ID        uuid.UUID      `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	Email     string         `gorm:"uniqueIndex;not null" json:"email"`
	Password  string         `gorm:"not null" json:"-"`
	Name      string         `gorm:"not null" json:"name"`
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`
}

// Workspace represents a workspace
type Workspace struct {
	ID          uuid.UUID         `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	Name        string            `gorm:"not null" json:"name"`
	Description string            `json:"description"`
	OwnerID     uuid.UUID         `gorm:"type:uuid;not null" json:"owner_id"`
	Owner       User              `gorm:"foreignKey:OwnerID" json:"owner,omitempty"`
	Members     []WorkspaceMember `gorm:"foreignKey:WorkspaceID" json:"members,omitempty"`
	CreatedAt   time.Time         `json:"created_at"`
	UpdatedAt   time.Time         `json:"updated_at"`
	DeletedAt   gorm.DeletedAt    `gorm:"index" json:"-"`
}

// WorkspaceMember represents workspace membership
type WorkspaceMember struct {
	ID          uuid.UUID      `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	WorkspaceID uuid.UUID      `gorm:"type:uuid;not null" json:"workspace_id"`
	UserID      uuid.UUID      `gorm:"type:uuid;not null" json:"user_id"`
	Role        string         `gorm:"not null;default:'member'" json:"role"` // admin, member, viewer
	User        User           `gorm:"foreignKey:UserID" json:"user,omitempty"`
	CreatedAt   time.Time      `json:"created_at"`
	DeletedAt   gorm.DeletedAt `gorm:"index" json:"-"`
}

// Collection represents an API collection
type Collection struct {
	ID           uuid.UUID      `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	Name         string         `gorm:"not null" json:"name"`
	Description  string         `json:"description"`
	WorkspaceID  uuid.UUID      `gorm:"type:uuid;not null" json:"workspace_id"`
	Workspace    Workspace      `gorm:"foreignKey:WorkspaceID" json:"workspace,omitempty"`
	RequestCount int            `gorm:"default:0" json:"request_count"`
	CreatedAt    time.Time      `json:"created_at"`
	UpdatedAt    time.Time      `json:"updated_at"`
	DeletedAt    gorm.DeletedAt `gorm:"index" json:"-"`
}

// Request represents an API request
type Request struct {
	ID           uuid.UUID      `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	Name         string         `gorm:"not null" json:"name"`
	Method       string         `gorm:"not null" json:"method"` // GET, POST, PUT, DELETE, PATCH, etc.
	URL          string         `gorm:"not null" json:"url"`
	Headers      string         `gorm:"type:jsonb" json:"headers"`      // JSON string
	QueryParams  string         `gorm:"type:jsonb" json:"query_params"` // JSON string
	Body         string         `gorm:"type:jsonb" json:"body"`         // JSON string
	Description  string         `json:"description"`
	CollectionID uuid.UUID      `gorm:"type:uuid;not null" json:"collection_id"`
	Collection   Collection     `gorm:"foreignKey:CollectionID" json:"collection,omitempty"`
	CreatedAt    time.Time      `json:"created_at"`
	UpdatedAt    time.Time      `json:"updated_at"`
	DeletedAt    gorm.DeletedAt `gorm:"index" json:"-"`
}

// Execution represents a request execution
type Execution struct {
	ID              uuid.UUID      `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	RequestID       uuid.UUID      `gorm:"type:uuid;not null" json:"request_id"`
	Request         Request        `gorm:"foreignKey:RequestID" json:"request,omitempty"`
	StatusCode      int            `json:"status_code"`
	ResponseTimeMs  int64          `json:"response_time_ms"`
	ResponseBody    string         `gorm:"type:text" json:"response_body"`
	ResponseHeaders string         `gorm:"type:jsonb" json:"response_headers"`
	TraceID         uuid.UUID      `gorm:"type:uuid" json:"trace_id"`
	SpanID          *uuid.UUID     `gorm:"type:uuid" json:"span_id,omitempty"`
	ParentSpanID    *uuid.UUID     `gorm:"type:uuid" json:"parent_span_id,omitempty"`
	ErrorMessage    string         `json:"error_message,omitempty"`
	Timestamp       time.Time      `gorm:"not null" json:"timestamp"`
	CreatedAt       time.Time      `json:"created_at"`
	DeletedAt       gorm.DeletedAt `gorm:"index" json:"-"`
}

// Trace represents a distributed trace
type Trace struct {
	ID              uuid.UUID      `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"trace_id"`
	WorkspaceID     uuid.UUID      `gorm:"type:uuid;not null" json:"workspace_id"`
	ServiceName     string         `gorm:"not null" json:"service_name"`
	SpanCount       int            `gorm:"default:0" json:"span_count"`
	TotalDurationMs float64        `json:"total_duration_ms"`
	StartTime       time.Time      `gorm:"not null" json:"start_time"`
	EndTime         time.Time      `json:"end_time"`
	Status          string         `gorm:"not null;default:'success'" json:"status"` // success, error, timeout
	Spans           []Span         `gorm:"foreignKey:TraceID" json:"spans"`
	CreatedAt       time.Time      `json:"created_at"`
	DeletedAt       gorm.DeletedAt `gorm:"index" json:"-"`
}

// Span represents a trace span
type Span struct {
	ID            uuid.UUID      `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"span_id"`
	TraceID       uuid.UUID      `gorm:"type:uuid;not null" json:"trace_id"`
	Trace         Trace          `gorm:"foreignKey:TraceID" json:"trace,omitempty"`
	ParentSpanID  *uuid.UUID     `gorm:"type:uuid" json:"parent_span_id"`
	OperationName string         `gorm:"not null" json:"operation_name"`
	ServiceName   string         `gorm:"not null" json:"service_name"`
	StartTime     time.Time      `gorm:"not null" json:"start_time"`
	DurationMs    float64        `json:"duration_ms"`
	Tags          string         `gorm:"type:jsonb" json:"tags"`     // JSON string
	Logs          string         `gorm:"type:jsonb" json:"logs"`     // JSON string
	Status        string         `gorm:"default:'ok'" json:"status"` // ok, error
	CreatedAt     time.Time      `json:"created_at"`
	DeletedAt     gorm.DeletedAt `gorm:"index" json:"-"`
}

// Annotation for collaborative debugging
type Annotation struct {
	ID        uuid.UUID      `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	SpanID    uuid.UUID      `gorm:"type:uuid;not null" json:"span_id"`
	Span      Span           `gorm:"foreignKey:SpanID" json:"span,omitempty"`
	UserID    uuid.UUID      `gorm:"type:uuid;not null" json:"user_id"`
	User      User           `gorm:"foreignKey:UserID" json:"user,omitempty"`
	Comment   string         `gorm:"type:text;not null" json:"comment"`
	Highlight bool           `gorm:"default:false" json:"highlight"`
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`
}

// Policy represents a governance policy
type Policy struct {
	ID          uuid.UUID      `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	WorkspaceID uuid.UUID      `gorm:"type:uuid;not null" json:"workspace_id"`
	Workspace   Workspace      `gorm:"foreignKey:WorkspaceID" json:"workspace,omitempty"`
	Name        string         `gorm:"not null" json:"name"`
	Description string         `json:"description"`
	Enabled     bool           `gorm:"default:true" json:"enabled"`
	Rules       string         `gorm:"type:jsonb;not null" json:"rules"` // JSON string
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `gorm:"index" json:"-"`
}

// UserSettings represents user preferences
type UserSettings struct {
	ID                   uuid.UUID      `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	UserID               uuid.UUID      `gorm:"type:uuid;uniqueIndex;not null" json:"user_id"`
	User                 User           `gorm:"foreignKey:UserID" json:"user,omitempty"`
	Theme                string         `gorm:"default:'light'" json:"theme"` // light, dark
	NotificationsEnabled bool           `gorm:"default:true" json:"notifications_enabled"`
	EmailNotifications   bool           `gorm:"default:true" json:"email_notifications"`
	Language             string         `gorm:"default:'en'" json:"language"`
	Timezone             string         `gorm:"default:'UTC'" json:"timezone"`
	Preferences          datatypes.JSON `gorm:"type:jsonb;default:'{}'" json:"preferences"` // JSON string for custom preferences
	CreatedAt            time.Time      `json:"created_at"`
	UpdatedAt            time.Time      `json:"updated_at"`
	DeletedAt            gorm.DeletedAt `gorm:"index" json:"-"`
}

// Replay represents a replay configuration
type Replay struct {
	ID                uuid.UUID      `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	WorkspaceID       uuid.UUID      `gorm:"type:uuid;not null" json:"workspace_id"`
	Workspace         Workspace      `gorm:"foreignKey:WorkspaceID" json:"workspace,omitempty"`
	Name              string         `gorm:"not null" json:"name"`
	Description       string         `json:"description"`
	SourceTraceID     uuid.UUID      `gorm:"type:uuid" json:"source_trace_id"`
	SourceRequestID   *uuid.UUID     `gorm:"type:uuid" json:"source_request_id"`
	TargetEnvironment string         `gorm:"not null" json:"target_environment"`
	Configuration     string         `gorm:"type:jsonb;not null" json:"configuration"` // JSON: mutations, variables, etc.
	Status            string         `gorm:"default:'pending'" json:"status"`          // pending, running, completed, failed
	CreatedBy         uuid.UUID      `gorm:"type:uuid;not null" json:"created_by"`
	CreatedAt         time.Time      `json:"created_at"`
	UpdatedAt         time.Time      `json:"updated_at"`
	DeletedAt         gorm.DeletedAt `gorm:"index" json:"-"`
}

// ReplayExecution represents a replay execution result
type ReplayExecution struct {
	ID               uuid.UUID      `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	ReplayID         uuid.UUID      `gorm:"type:uuid;not null" json:"replay_id"`
	Replay           Replay         `gorm:"foreignKey:ReplayID" json:"replay,omitempty"`
	ExecutionTraceID uuid.UUID      `gorm:"type:uuid" json:"execution_trace_id"`
	Status           string         `gorm:"not null" json:"status"` // success, error, timeout
	StartTime        time.Time      `gorm:"not null" json:"start_time"`
	EndTime          time.Time      `json:"end_time"`
	DurationMs       int64          `json:"duration_ms"`
	Results          string         `gorm:"type:jsonb" json:"results"` // JSON: comparison data
	ErrorMessage     string         `json:"error_message,omitempty"`
	CreatedAt        time.Time      `json:"created_at"`
	DeletedAt        gorm.DeletedAt `gorm:"index" json:"-"`
}

// Mock represents a mock service
type Mock struct {
	ID              uuid.UUID      `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	WorkspaceID     uuid.UUID      `gorm:"type:uuid;not null" json:"workspace_id"`
	Workspace       Workspace      `gorm:"foreignKey:WorkspaceID" json:"workspace,omitempty"`
	Name            string         `gorm:"not null" json:"name"`
	Description     string         `json:"description"`
	Method          string         `gorm:"not null" json:"method"`
	PathPattern     string         `gorm:"not null" json:"path_pattern"`
	ResponseBody    string         `gorm:"type:jsonb" json:"response_body"`
	ResponseHeaders string         `gorm:"type:jsonb" json:"response_headers"`
	StatusCode      int            `gorm:"default:200" json:"status_code"`
	Latency         int            `gorm:"default:0" json:"latency"` // milliseconds
	Enabled         bool           `gorm:"default:true" json:"enabled"`
	SourceTraceID   *uuid.UUID     `gorm:"type:uuid" json:"source_trace_id"`
	CreatedAt       time.Time      `json:"created_at"`
	UpdatedAt       time.Time      `json:"updated_at"`
	DeletedAt       gorm.DeletedAt `gorm:"index" json:"-"`
}

// RefreshToken for JWT token refresh
type RefreshToken struct {
	ID        uuid.UUID      `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	UserID    uuid.UUID      `gorm:"type:uuid;not null" json:"user_id"`
	User      User           `gorm:"foreignKey:UserID" json:"user,omitempty"`
	Token     string         `gorm:"uniqueIndex;not null" json:"token"`
	ExpiresAt time.Time      `gorm:"not null" json:"expires_at"`
	CreatedAt time.Time      `json:"created_at"`
	RevokedAt *time.Time     `json:"revoked_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`
}

// models/models.go - Add these models

type Environment struct {
	ID          uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	WorkspaceID uuid.UUID `gorm:"type:uuid;not null"`
	Name        string    `gorm:"type:varchar(255);not null"`
	Type        string    `gorm:"type:varchar(50);not null"` // global, development, staging, production
	Description string    `gorm:"type:text"`
	IsActive    bool      `gorm:"default:true"`
	CreatedAt   time.Time
	UpdatedAt   time.Time
	DeletedAt   gorm.DeletedAt `gorm:"index"`

	Workspace Workspace `gorm:"foreignKey:WorkspaceID"`
	Variables []EnvironmentVariable
	Secrets   []EnvironmentSecret
}

type EnvironmentVariable struct {
	ID            uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	EnvironmentID uuid.UUID `gorm:"type:uuid;not null"`
	Key           string    `gorm:"type:varchar(255);not null"`
	Value         string    `gorm:"type:text;not null"`
	Type          string    `gorm:"type:varchar(50)"` // string, number, boolean, json
	Description   string    `gorm:"type:text"`
	CreatedAt     time.Time
	UpdatedAt     time.Time
	DeletedAt     gorm.DeletedAt `gorm:"index"`

	Environment Environment `gorm:"foreignKey:EnvironmentID"`
}

type EnvironmentSecret struct {
	ID            uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	EnvironmentID uuid.UUID `gorm:"type:uuid;not null"`
	Key           string    `gorm:"type:varchar(255);not null"`
	Value         string    `gorm:"type:text;not null"`
	Description   string    `gorm:"type:text"`
	CreatedAt     time.Time
	UpdatedAt     time.Time
	DeletedAt     gorm.DeletedAt `gorm:"index"`

	Environment Environment `gorm:"foreignKey:EnvironmentID"`
}

type ServiceTracingConfig struct {
	ID                  uuid.UUID      `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	WorkspaceID         uuid.UUID      `gorm:"type:uuid;not null" json:"workspace_id"`
	Workspace           Workspace      `gorm:"foreignKey:WorkspaceID" json:"workspace,omitempty"`
	ServiceName         string         `gorm:"not null" json:"service_name"`
	Enabled             bool           `gorm:"default:true" json:"enabled"`
	SamplingRate        float64        `gorm:"default:1.0" json:"sampling_rate"`
	LogTraceHeaders     bool           `gorm:"default:true" json:"log_trace_headers"`
	PropagateContext    bool           `gorm:"default:true" json:"propagate_context"`
	CaptureRequestBody  bool           `gorm:"default:false" json:"capture_request_body"`
	CaptureResponseBody bool           `gorm:"default:false" json:"capture_response_body"`
	MaxBodySizeBytes    int            `gorm:"default:10240" json:"max_body_size_bytes"`
	ExcludePaths        string         `gorm:"type:jsonb;default:'[]'" json:"exclude_paths"`
	CustomTags          string         `gorm:"type:jsonb;default:'{}'" json:"custom_tags"`
	Description         string         `gorm:"type:text" json:"description"`
	CreatedAt           time.Time      `json:"created_at"`
	UpdatedAt           time.Time      `json:"updated_at"`
	DeletedAt           gorm.DeletedAt `gorm:"index" json:"-"`
}
