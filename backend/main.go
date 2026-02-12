package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"backend/config"
	"backend/database"
	"backend/handlers"
	"backend/middlewares"
	"backend/services"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

func main() {
	// Load configuration
	cfg := config.Load()

	// Initialize database
	db, err := database.InitDB(cfg)
	if err != nil {
		log.Fatalf("Failed to initialize database: %v", err)
	}
	defer database.CloseDB(db)

	// Run migrations
	if err := database.RunMigrations(db); err != nil {
		log.Fatalf("Failed to run migrations: %v", err)
	}

	// Initialize services
	alertingService := services.NewAlertingService(db)
	auditService := services.NewAuditService(db)
	authService := services.NewAuthService(db, cfg)
	collectionService := services.NewCollectionService(db)
	environmentService := services.NewEnvironmentService(db)
	failureInjectionService := services.NewFailureInjectionService(db)
	governanceService := services.NewGovernanceService(db)
	loadTestService := services.NewLoadTestService(db)
	mockService := services.NewMockService(db)
	monitoringService := services.NewMonitoringService(db)
	mutationService := services.NewMutationService()
	percentileCalculator := services.NewPercentileCalculator()
	replayService := services.NewReplayService(db)
	requestService := services.NewRequestService(db)
	schemaValidator := services.NewSchemaValidator()
	secretsService := services.NewSecretsService(db, cfg.EncryptionKey)
	settingsService := services.NewSettingsService(db)
	testDataGenerator := services.NewTestDataGenerator()
	traceService := services.NewTraceService(db)
	tracingConfigService := services.NewTracingConfigService(db)
	waterfallService := services.NewWaterfallService(db)
	webhookService := services.NewWebhookService(db)
	workflowService := services.NewWorkflowService(db)
	workspaceService := services.NewWorkspaceService(db)

	// Initialize handlers
	alertHandler := handlers.NewAlertHandler(alertingService)
	auditHandler := handlers.NewAuditHandler(auditService)
	authHandler := handlers.NewAuthHandler(authService)
	collectionHandler := handlers.NewCollectionHandler(collectionService)
	environmentHandler := handlers.NewEnvironmentHandler(environmentService)
	failureInjectionHandler := handlers.NewFailureInjectionHandler(failureInjectionService)
	governanceHandler := handlers.NewGovernanceHandler(governanceService)
	loadTestHandler := handlers.NewLoadTestHandler(loadTestService)
	mockHandler := handlers.NewMockHandler(mockService)
	monitoringHandler := handlers.NewMonitoringHandler(monitoringService)
	mutationHandler := handlers.NewMutationHandler(mutationService)
	percentileCalculatorHandler := handlers.NewPercentileCalculatorHandler(percentileCalculator)
	replayHandler := handlers.NewReplayHandler(replayService)
	requestHandler := handlers.NewRequestHandler(requestService)
	schemaValidatorHandler := handlers.NewSchemaValidatorHandler(schemaValidator)
	secretsHandler := handlers.NewSecretsHandler(secretsService)
	settingsHandler := handlers.NewSettingsHandler(settingsService)
	testDataGeneratorHandler := handlers.NewTestDataGeneratorHandler(testDataGenerator)
	traceHandler := handlers.NewTraceHandler(traceService)
	tracingConfigHandler := handlers.NewTracingConfigHandler(tracingConfigService)
	waterfallHandler := handlers.NewWaterfallHandler(waterfallService)
	webhookHandler := handlers.NewWebhookHandler(webhookService)
	workflowHandler := handlers.NewWorkflowHandler(workflowService)
	workspaceHandler := handlers.NewWorkspaceHandler(workspaceService)

	// Setup router
	router := setupRouter(cfg, authService, alertHandler, auditHandler, authHandler, collectionHandler,
		environmentHandler, failureInjectionHandler, governanceHandler, loadTestHandler, mockHandler,
		monitoringHandler, mutationHandler, percentileCalculatorHandler, replayHandler, requestHandler,
		schemaValidatorHandler, secretsHandler, settingsHandler, testDataGeneratorHandler, traceHandler,
		tracingConfigHandler, waterfallHandler, webhookHandler, workflowHandler, workspaceHandler)

	// Create server
	srv := &http.Server{
		Addr:         fmt.Sprintf(":%s", cfg.Port),
		Handler:      router,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Start server in goroutine
	go func() {
		log.Printf("Starting server on port %s", cfg.Port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Failed to start server: %v", err)
		}
	}()

	// Graceful shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down server...")
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("Server forced to shutdown: %v", err)
	}

	log.Println("Server exited")
}

func setupRouter(cfg *config.Config, authService *services.AuthService,
	alertHandler *handlers.AlertHandler,
	auditHandler *handlers.AuditHandler,
	authHandler *handlers.AuthHandler,
	collectionHandler *handlers.CollectionHandler,
	environmentHandler *handlers.EnvironmentHandler,
	failureInjectionHandler *handlers.FailureInjectionHandler,
	governanceHandler *handlers.GovernanceHandler,
	loadTestHandler *handlers.LoadTestHandler,
	mockHandler *handlers.MockHandler,
	monitoringHandler *handlers.MonitoringHandler,
	mutationHandler *handlers.MutationHandler,
	percentileCalculatorHandler *handlers.PercentileCalculatorHandler,
	replayHandler *handlers.ReplayHandler,
	requestHandler *handlers.RequestHandler,
	schemaValidatorHandler *handlers.SchemaValidatorHandler,
	secretsHandler *handlers.SecretsHandler,
	settingsHandler *handlers.SettingsHandler,
	testDataGeneratorHandler *handlers.TestDataGeneratorHandler,
	traceHandler *handlers.TraceHandler,
	tracingConfigHandler *handlers.TracingConfigHandler,
	waterfallHandler *handlers.WaterfallHandler,
	webhookHandler *handlers.WebhookHandler,
	workflowHandler *handlers.WorkflowHandler,
	workspaceHandler *handlers.WorkspaceHandler) *gin.Engine {

	if cfg.Environment == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	router := gin.Default()

	// CORS configuration
	corsConfig := cors.Config{
		AllowOrigins:     cfg.CORSOrigins,
		AllowMethods:     []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization", "X-Trace-ID"},
		ExposeHeaders:    []string{"Content-Length", "X-Trace-ID"},
		AllowCredentials: true,
		AllowOriginFunc: func(origin string) bool {
			// allow any localhost port dynamically
			return origin == "http://localhost" ||
				origin == "http://127.0.0.1" ||
				strings.HasPrefix(origin, "http://localhost:") ||
				strings.HasPrefix(origin, "http://127.0.0.1:")
		},
		MaxAge: 12 * time.Hour,
	}
	router.Use(cors.New(corsConfig))

	// Global middlewares
	router.Use(middlewares.RequestLogger())
	router.Use(middlewares.ErrorHandler())
	router.Use(middlewares.TraceID())

	// Health check
	router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "healthy"})
	})

	// API v1 routes
	v1 := router.Group("/api/v1")
	{
		// Authentication routes (public)
		auth := v1.Group("/auth")
		{
			auth.POST("/login", authHandler.Login)
			auth.POST("/register", authHandler.Register)
			auth.POST("/refresh", authHandler.RefreshToken)
			auth.POST("/logout", middlewares.AuthMiddleware(authService), authHandler.Logout)
			auth.POST("/verify", middlewares.AuthMiddleware(authService), authHandler.VerifyToken)
		}

		// Protected routes
		protected := v1.Group("")
		protected.Use(middlewares.AuthMiddleware(authService))
		{
			// Workspace routes
			workspaces := protected.Group("/workspaces")
			{
				workspaces.GET("", workspaceHandler.GetAll)
				workspaces.POST("", workspaceHandler.Create)
				workspaces.GET("/:workspace_id", workspaceHandler.GetByID)
				workspaces.PUT("/:workspace_id", workspaceHandler.Update)
				workspaces.DELETE("/:workspace_id", workspaceHandler.Delete)

				// Collection routes
				workspaces.GET("/:workspace_id/collections", collectionHandler.GetAll)
				workspaces.POST("/:workspace_id/collections", collectionHandler.Create)
				workspaces.GET("/:workspace_id/collections/:collection_id", collectionHandler.GetByID)
				workspaces.PUT("/:workspace_id/collections/:collection_id", collectionHandler.Update)
				workspaces.DELETE("/:workspace_id/collections/:collection_id", collectionHandler.Delete)

				// Request routes
				workspaces.POST("/:workspace_id/collections/:collection_id/requests", requestHandler.Create)
				workspaces.GET("/:workspace_id/requests/:request_id", requestHandler.GetByID)
				workspaces.PUT("/:workspace_id/requests/:request_id", requestHandler.Update)
				workspaces.DELETE("/:workspace_id/requests/:request_id", requestHandler.Delete)
				workspaces.POST("/:workspace_id/requests/:request_id/execute", requestHandler.Execute)
				workspaces.GET("/:workspace_id/requests/:request_id/history", requestHandler.GetHistory)

				// Trace routes
				workspaces.GET("/:workspace_id/traces", traceHandler.GetTraces)
				workspaces.GET("/:workspace_id/traces/:trace_id", traceHandler.GetTraceDetails)
				workspaces.POST("/:workspace_id/traces/:trace_id/annotate", traceHandler.AddAnnotation)
				workspaces.GET("/:workspace_id/traces/:trace_id/critical-path", traceHandler.GetCriticalPath)

				// Monitoring routes
				workspaces.GET("/:workspace_id/monitoring/dashboard", monitoringHandler.GetDashboard)
				workspaces.GET("/:workspace_id/monitoring/metrics", monitoringHandler.GetMetrics)
				workspaces.GET("/:workspace_id/monitoring/topology", monitoringHandler.GetTopology)

				// Governance routes
				workspaces.GET("/:workspace_id/governance/policies", governanceHandler.GetPolicies)
				workspaces.POST("/:workspace_id/governance/policies", governanceHandler.CreatePolicy)
				workspaces.PUT("/:workspace_id/governance/policies/:policy_id", governanceHandler.UpdatePolicy)
				workspaces.DELETE("/:workspace_id/governance/policies/:policy_id", governanceHandler.DeletePolicy)

				// Replay routes
				workspaces.POST("/:workspace_id/replays", replayHandler.CreateReplay)
				workspaces.GET("/:workspace_id/replays/:replay_id", replayHandler.GetReplay)
				workspaces.POST("/:workspace_id/replays/:replay_id/execute", replayHandler.ExecuteReplay)
				workspaces.GET("/:workspace_id/replays/:replay_id/results", replayHandler.GetResults)

				// Mock routes
				workspaces.POST("/:workspace_id/mocks/generate", mockHandler.GenerateFromTrace)
				workspaces.GET("/:workspace_id/mocks", mockHandler.GetAll)
				workspaces.PUT("/:workspace_id/mocks/:mock_id", mockHandler.Update)
				workspaces.DELETE("/:workspace_id/mocks/:mock_id", mockHandler.Delete)

				// ========== ENVIRONMENT ROUTES ==========
				workspaces.GET("/:workspace_id/environments", environmentHandler.GetEnvironments)
				workspaces.POST("/:workspace_id/environments", environmentHandler.CreateEnvironment)
				workspaces.GET("/:workspace_id/environments/:environment_id", environmentHandler.GetEnvironmentVariables)
				workspaces.PUT("/:workspace_id/environments/:environment_id", environmentHandler.UpdateEnvironment)
				workspaces.DELETE("/:workspace_id/environments/:environment_id", environmentHandler.DeleteEnvironment)
				workspaces.POST("/:workspace_id/environments/:environment_id/variables", environmentHandler.AddEnvironmentVariable)
				workspaces.PUT("/:workspace_id/environments/:environment_id/variables/:variable_id", environmentHandler.UpdateEnvironmentVariable)
				workspaces.DELETE("/:workspace_id/environments/:environment_id/variables/:variable_id", environmentHandler.DeleteEnvironmentVariable)

				// ========== TRACING CONFIG ROUTES ==========
				workspaces.GET("/:workspace_id/tracing/configs", tracingConfigHandler.GetAll)
				workspaces.POST("/:workspace_id/tracing/configs", tracingConfigHandler.Create)
				workspaces.GET("/:workspace_id/tracing/configs/:config_id", tracingConfigHandler.GetByID)
				workspaces.PUT("/:workspace_id/tracing/configs/:config_id", tracingConfigHandler.Update)
				workspaces.DELETE("/:workspace_id/tracing/configs/:config_id", tracingConfigHandler.Delete)
				workspaces.POST("/:workspace_id/tracing/configs/:config_id/toggle", tracingConfigHandler.Toggle)
				workspaces.POST("/:workspace_id/tracing/configs/bulk-toggle", tracingConfigHandler.BulkToggle)
				workspaces.GET("/:workspace_id/tracing/services/:service_name", tracingConfigHandler.GetByServiceName)
				workspaces.GET("/:workspace_id/tracing/enabled-services", tracingConfigHandler.GetEnabledServices)
				workspaces.GET("/:workspace_id/tracing/disabled-services", tracingConfigHandler.GetDisabledServices)
				workspaces.GET("/:workspace_id/tracing/check", tracingConfigHandler.CheckTracingEnabled)

				// ========== AUDIT ROUTES ==========
				workspaces.GET("/:workspace_id/audit/logs", auditHandler.GetLogs)
				workspaces.POST("/:workspace_id/audit/anomalies/:target_user_id", auditHandler.DetectAnomalies)

				// ========== FAILURE INJECTION ROUTES ==========
				workspaces.POST("/:workspace_id/failure-injection/rules", failureInjectionHandler.CreateRule)

				// ========== MUTATION ROUTES ==========
				workspaces.POST("/:workspace_id/mutations/apply", mutationHandler.ApplyMutations)

				// ========== PERCENTILE CALCULATOR ROUTES ==========
				workspaces.POST("/:workspace_id/percentiles/calculate", percentileCalculatorHandler.CalculatePercentiles)

				// ========== SCHEMA VALIDATOR ROUTES ==========
				workspaces.POST("/:workspace_id/schema/validate", schemaValidatorHandler.ValidateSchema)

				// ========== TEST DATA GENERATOR ROUTES ==========
				// 1. Ensure the schema generation path matches Flutter
				workspaces.POST("/:workspace_id/test-data/generate", testDataGeneratorHandler.GenerateFromSchema)

				// 2. Add the missing route for realistic data (user, product, etc.)
				workspaces.GET("/:workspace_id/test-data/realistic/:type", testDataGeneratorHandler.GenerateRealisticData)

				// ========== WATERFALL ROUTES ==========
				workspaces.GET("/:workspace_id/traces/:trace_id/waterfall", waterfallHandler.GetWaterfall)

				// ========== ALERT ROUTES ==========
				workspaces.POST("/:workspace_id/alerts/rules", alertHandler.CreateRule)
				workspaces.GET("/:workspace_id/alerts/active", alertHandler.GetActiveAlerts)
				workspaces.POST("/:workspace_id/alerts/:alert_id/acknowledge", alertHandler.AcknowledgeAlert)

				// ========== LOAD TEST ROUTES ==========
				workspaces.POST("/:workspace_id/load-tests", loadTestHandler.Create)

				// ========== SECRETS ROUTES ==========
				workspaces.POST("/:workspace_id/secrets", secretsHandler.Create)
				workspaces.GET("/:workspace_id/secrets/:secret_id", secretsHandler.GetValue)
				workspaces.POST("/:workspace_id/secrets/:secret_id/rotate", secretsHandler.Rotate)

				// ========== WEBHOOK ROUTES ==========
				workspaces.POST("/:workspace_id/webhooks", webhookHandler.Create)
				workspaces.POST("/:workspace_id/webhooks/trigger", webhookHandler.Trigger)

				// ========== WORKFLOW ROUTES ==========
				workspaces.POST("/:workspace_id/workflows", workflowHandler.Create)
				workspaces.POST("/:workspace_id/workflows/:workflow_id/execute", workflowHandler.Execute)
			}

			// User settings routes
			protected.GET("/users/settings", settingsHandler.GetSettings)
			protected.PUT("/users/settings", settingsHandler.UpdateSettings)
		}
	}

	return router
}
