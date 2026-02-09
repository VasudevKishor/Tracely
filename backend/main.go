package main

import (
	"log"

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
	
	// Create tables if not exist (migrations)
	if err := database.RunMigrations(db); err != nil {
		log.Fatalf("Failed to run migrations: %v", err)
	}

	// Initialize Services
	authService := services.NewAuthService(db, cfg)
	workspaceService := services.NewWorkspaceService(db)
	collectionService := services.NewCollectionService(db)
	requestService := services.NewRequestService(db)
	traceService := services.NewTraceService(db)
	monitoringService := services.NewMonitoringService(db)
	governanceService := services.NewGovernanceService(db)
	settingsService := services.NewSettingsService(db)
	replayService := services.NewReplayService(db)
	mockService := services.NewMockService(db)
	environmentService := services.NewEnvironmentService(db)
	secretsService := services.NewSecretsService(db, cfg.JWTSecret)
	workflowService := services.NewWorkflowService(db)
	tracingConfigService := services.NewTracingConfigService(db)
	alertingService := services.NewAlertingService(db)
	loadTestService := services.NewLoadTestService(db)


	// Initialize Handlers
	authHandler := handlers.NewAuthHandler(authService)
	workspaceHandler := handlers.NewWorkspaceHandler(workspaceService)
	collectionHandler := handlers.NewCollectionHandler(collectionService)
	requestHandler := handlers.NewRequestHandler(requestService)
	traceHandler := handlers.NewTraceHandler(traceService)
	monitoringHandler := handlers.NewMonitoringHandler(monitoringService)
	governanceHandler := handlers.NewGovernanceHandler(governanceService)
	settingsHandler := handlers.NewSettingsHandler(settingsService)
	replayHandler := handlers.NewReplayHandler(replayService)
	mockHandler := handlers.NewMockHandler(mockService)
	environmentHandler := handlers.NewEnvironmentHandler(environmentService)
	secretsHandler := handlers.NewSecretsHandler(secretsService)
	workflowHandler := handlers.NewWorkflowHandler(workflowService)
	tracingConfigHandler := handlers.NewTracingConfigHandler(tracingConfigService)
	alertHandler := handlers.NewAlertHandler(alertingService)
	loadTestHandler := handlers.NewLoadTestHandler(loadTestService)

	// Initialize Router
	r := gin.Default()

	// Middleware
	r.Use(middlewares.ErrorHandler())
	r.Use(middlewares.RequestLogger())
	
	// CORS
	corsConfig := cors.DefaultConfig()
	corsConfig.AllowAllOrigins = true // For development convenience
	corsConfig.AllowHeaders = []string{"Origin", "Content-Length", "Content-Type", "Authorization"}
	r.Use(cors.New(corsConfig))

	// Routes
	api := r.Group("/api/v1")
	{
		// Auth
		auth := api.Group("/auth")
		{
			auth.POST("/register", authHandler.Register)
			auth.POST("/login", authHandler.Login)
			auth.POST("/verify", authHandler.VerifyToken)
			auth.POST("/refresh", authHandler.RefreshToken)
			auth.POST("/logout", authHandler.Logout)
		}

		// Protected routes
		protected := api.Group("/")
		protected.Use(middlewares.AuthMiddleware(authService))
		{
			// User Settings
			protected.GET("/users/settings", settingsHandler.GetSettings)
			protected.PUT("/users/settings", settingsHandler.UpdateSettings)

			// Workspaces
			workspaces := protected.Group("/workspaces")
			{
				workspaces.GET("", workspaceHandler.GetAll)
				workspaces.POST("", workspaceHandler.Create)
				workspaces.GET("/:workspace_id", workspaceHandler.GetByID)
				workspaces.PUT("/:workspace_id", workspaceHandler.Update)
				workspaces.DELETE("/:workspace_id", workspaceHandler.Delete)

				// Collections setup
				workspaces.GET("/:workspace_id/collections", collectionHandler.GetAll)
				workspaces.POST("/:workspace_id/collections", collectionHandler.Create)
				workspaces.GET("/:workspace_id/collections/:collection_id", collectionHandler.GetByID)
				workspaces.PUT("/:workspace_id/collections/:collection_id", collectionHandler.Update)
				workspaces.DELETE("/:workspace_id/collections/:collection_id", collectionHandler.Delete)

				// Requests setup
				workspaces.POST("/:workspace_id/collections/:collection_id/requests", requestHandler.Create)
				workspaces.GET("/:workspace_id/requests/:request_id", requestHandler.GetByID)
				workspaces.PUT("/:workspace_id/requests/:request_id", requestHandler.Update)
				workspaces.DELETE("/:workspace_id/requests/:request_id", requestHandler.Delete)
				workspaces.POST("/:workspace_id/requests/:request_id/execute", requestHandler.Execute)
				workspaces.GET("/:workspace_id/requests/:request_id/history", requestHandler.GetHistory)
				
				// Traces
				workspaces.GET("/:workspace_id/traces", traceHandler.GetTraces)
				workspaces.GET("/:workspace_id/traces/:trace_id", traceHandler.GetTraceDetails)
				workspaces.POST("/:workspace_id/traces/:trace_id/annotate", traceHandler.AddAnnotation)
				workspaces.GET("/:workspace_id/traces/:trace_id/critical-path", traceHandler.GetCriticalPath)

				// Monitoring
				workspaces.GET("/:workspace_id/monitoring/dashboard", monitoringHandler.GetDashboard)
				workspaces.GET("/:workspace_id/monitoring/metrics", monitoringHandler.GetMetrics)
				workspaces.GET("/:workspace_id/monitoring/topology", monitoringHandler.GetTopology)

				// Governance
				workspaces.GET("/:workspace_id/governance/policies", governanceHandler.GetPolicies)
				workspaces.POST("/:workspace_id/governance/policies", governanceHandler.CreatePolicy)
				workspaces.PUT("/:workspace_id/governance/policies/:policy_id", governanceHandler.UpdatePolicy)
				workspaces.DELETE("/:workspace_id/governance/policies/:policy_id", governanceHandler.DeletePolicy)

				// Replays
				workspaces.POST("/:workspace_id/replays", replayHandler.CreateReplay)
				workspaces.GET("/:workspace_id/replays/:replay_id", replayHandler.GetReplay)
				workspaces.POST("/:workspace_id/replays/:replay_id/execute", replayHandler.ExecuteReplay)
				workspaces.GET("/:workspace_id/replays/:replay_id/results", replayHandler.GetResults)

				// Mocks
				workspaces.POST("/:workspace_id/mocks/generate", mockHandler.GenerateFromTrace)
				workspaces.GET("/:workspace_id/mocks", mockHandler.GetAll)
				workspaces.PUT("/:workspace_id/mocks/:mock_id", mockHandler.Update)
				workspaces.DELETE("/:workspace_id/mocks/:mock_id", mockHandler.Delete)
				
				// Environments
				workspaces.POST("/:workspace_id/environments", environmentHandler.Create)
				workspaces.GET("/:workspace_id/environments", environmentHandler.GetAll)
				workspaces.GET("/:workspace_id/environments/:environment_id", environmentHandler.GetByID)
				workspaces.PUT("/:workspace_id/environments/:environment_id", environmentHandler.Update)
				workspaces.DELETE("/:workspace_id/environments/:environment_id", environmentHandler.Delete)
				
				// Secrets
				workspaces.POST("/:workspace_id/secrets", secretsHandler.Create)
				workspaces.GET("/:workspace_id/secrets/:secret_id", secretsHandler.GetValue)
				workspaces.POST("/:workspace_id/secrets/:secret_id/rotate", secretsHandler.Rotate)
				
				// Workflows
				workspaces.POST("/:workspace_id/workflows", workflowHandler.Create)
				workspaces.POST("/:workspace_id/workflows/:workflow_id/execute", workflowHandler.Execute)
				
				// Tracing Config
				workspaces.GET("/:workspace_id/tracing-config", tracingConfigHandler.GetAll)
				workspaces.GET("/:workspace_id/services/:service_name/tracing-config", tracingConfigHandler.GetByServiceName)
				workspaces.POST("/:workspace_id/tracing-config", tracingConfigHandler.Create)
				workspaces.PUT("/:workspace_id/tracing-config/:config_id", tracingConfigHandler.Update)
				
				// Alerts
				workspaces.POST("/:workspace_id/alerts", alertHandler.CreateRule)
				workspaces.GET("/:workspace_id/alerts/active", alertHandler.GetActiveAlerts)
				workspaces.POST("/:workspace_id/alerts/:alert_id/acknowledge", alertHandler.AcknowledgeAlert)
				
				// Load Tests
				workspaces.POST("/:workspace_id/load-tests", loadTestHandler.Create)
			}
		}
	}

	// Start server
	log.Printf("Server starting on port %s", cfg.Port)
	if err := r.Run(":" + cfg.Port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}