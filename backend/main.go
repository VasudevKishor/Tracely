package main

import (
	"log"
	"net/http"

	"backend/config"
	"backend/database"
	"backend/handlers"
	"backend/middlewares"
	"backend/services"

	"github.com/gin-gonic/gin"
)

func main() {
	cfg := config.Load()
	db, err := database.InitDB(cfg)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer database.CloseDB(db)

	if err := database.RunMigrations(db); err != nil {
		log.Fatalf("Migrations failed: %v", err)
	}

	gin.SetMode(gin.ReleaseMode)
	if cfg.Environment == "development" {
		gin.SetMode(gin.DebugMode)
	}

	router := gin.New()
	router.Use(gin.Recovery())
	router.Use(middlewares.RequestLogger())
	router.Use(middlewares.TraceID())
	router.Use(middlewares.ErrorHandler())

	// CORS
	router.Use(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Origin, Content-Type, Authorization, X-Trace-ID, X-Span-ID, X-Parent-Span-ID")
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}
		c.Next()
	})

	// Services
	authService := services.NewAuthService(db, cfg)
	workspaceService := services.NewWorkspaceService(db)
	collectionService := services.NewCollectionService(db)
	requestService := services.NewRequestService(db)
	traceService := services.NewTraceService(db)
	waterfallService := services.NewWaterfallService(db)
	tracingConfigService := services.NewTracingConfigService(db)
	monitoringService := services.NewMonitoringService(db)
	governanceService := services.NewGovernanceService(db)
	replayService := services.NewReplayService(db)
	mockService := services.NewMockService(db)
	workflowService := services.NewWorkflowService(db)
	environmentService := services.NewEnvironmentService(db)
	secretsService := services.NewSecretsService(db, cfg.JWTSecret)
	settingsService := services.NewSettingsService(db)
	alertingService := services.NewAlertingService(db)
	loadTestService := services.NewLoadTestService(db)

	// Handlers
	authHandler := handlers.NewAuthHandler(authService)
	workspaceHandler := handlers.NewWorkspaceHandler(workspaceService)
	collectionHandler := handlers.NewCollectionHandler(collectionService)
	requestHandler := handlers.NewRequestHandler(requestService)
	traceHandler := handlers.NewTraceHandler(traceService, waterfallService)
	tracingConfigHandler := handlers.NewTracingConfigHandler(tracingConfigService)
	monitoringHandler := handlers.NewMonitoringHandler(monitoringService)
	governanceHandler := handlers.NewGovernanceHandler(governanceService)
	replayHandler := handlers.NewReplayHandler(replayService)
	mockHandler := handlers.NewMockHandler(mockService)
	workflowHandler := handlers.NewWorkflowHandler(workflowService)
	environmentHandler := handlers.NewEnvironmentHandler(environmentService)
	secretsHandler := handlers.NewSecretsHandler(secretsService)
	settingsHandler := handlers.NewSettingsHandler(settingsService)
	alertHandler := handlers.NewAlertHandler(alertingService)
	loadTestHandler := handlers.NewLoadTestHandler(loadTestService)

	api := router.Group("/api/v1")
	{
		// Auth (no auth middleware)
		api.POST("/auth/login", authHandler.Login)
		api.POST("/auth/register", authHandler.Register)
		api.POST("/auth/logout", authHandler.Logout)
		api.POST("/auth/refresh", authHandler.RefreshToken)

		// Protected routes
		auth := api.Group("")
		auth.Use(middlewares.AuthMiddleware(authService))
		{
			auth.POST("/auth/verify", authHandler.VerifyToken)

			// Users
			auth.GET("/users/settings", settingsHandler.GetSettings)
			auth.PUT("/users/settings", settingsHandler.UpdateSettings)

			// Workspaces
			auth.GET("/workspaces", workspaceHandler.GetAll)
			auth.POST("/workspaces", workspaceHandler.Create)
			auth.GET("/workspaces/:workspace_id", workspaceHandler.GetByID)
			auth.PUT("/workspaces/:workspace_id", workspaceHandler.Update)
			auth.DELETE("/workspaces/:workspace_id", workspaceHandler.Delete)

			// Workspace-scoped routes
			w := auth.Group("/workspaces/:workspace_id")
			{
				// Collections
				w.GET("/collections", collectionHandler.GetAll)
				w.POST("/collections", collectionHandler.Create)
				w.GET("/collections/:collection_id", collectionHandler.GetByID)
				w.PUT("/collections/:collection_id", collectionHandler.Update)
				w.DELETE("/collections/:collection_id", collectionHandler.Delete)

				// Requests (under collection)
				w.POST("/collections/:collection_id/requests", requestHandler.Create)
				w.GET("/collections/:collection_id/requests", requestHandler.GetByCollection)
				w.GET("/requests/:request_id", requestHandler.GetByID)
				w.PUT("/requests/:request_id", requestHandler.Update)
				w.DELETE("/requests/:request_id", requestHandler.Delete)
				w.POST("/requests/:request_id/execute", requestHandler.Execute)
				w.GET("/requests/:request_id/history", requestHandler.GetHistory)

				// Traces
				w.GET("/traces", traceHandler.GetTraces)
				w.GET("/traces/:trace_id", traceHandler.GetTraceDetails)
				w.GET("/traces/:trace_id/waterfall", traceHandler.GetWaterfall)
				w.GET("/traces/:trace_id/critical-path", traceHandler.GetCriticalPath)
				w.POST("/spans/:span_id/annotations", traceHandler.AddAnnotation)

				// Tracing config
				w.GET("/tracing/configs", tracingConfigHandler.GetAll)
				w.POST("/tracing/configs", tracingConfigHandler.Create)
				w.GET("/tracing/configs/:config_id", tracingConfigHandler.GetByID)
				w.PUT("/tracing/configs/:config_id", tracingConfigHandler.Update)
				w.DELETE("/tracing/configs/:config_id", tracingConfigHandler.Delete)
				w.POST("/tracing/configs/:config_id/toggle", tracingConfigHandler.Toggle)
				w.POST("/tracing/configs/bulk-toggle", tracingConfigHandler.BulkToggle)
				w.GET("/tracing/services/:service_name", tracingConfigHandler.GetByServiceName)
				w.GET("/tracing/enabled-services", tracingConfigHandler.GetEnabledServices)
				w.GET("/tracing/disabled-services", tracingConfigHandler.GetDisabledServices)
				w.GET("/tracing/check", tracingConfigHandler.Check)

				// Monitoring
				w.GET("/monitoring/dashboard", monitoringHandler.GetDashboard)
				w.GET("/monitoring/metrics", monitoringHandler.GetMetrics)
				w.GET("/monitoring/topology", monitoringHandler.GetTopology)
				w.GET("/monitoring/service-latencies", monitoringHandler.GetServiceLatencies)

				// Governance
				w.GET("/governance/policies", governanceHandler.GetPolicies)
				w.POST("/governance/policies", governanceHandler.CreatePolicy)
				w.PUT("/governance/policies/:policy_id", governanceHandler.UpdatePolicy)
				w.DELETE("/governance/policies/:policy_id", governanceHandler.DeletePolicy)

				// Replays
				w.GET("/replays", replayHandler.GetAll)
				w.POST("/replays", replayHandler.CreateReplay)
				w.GET("/replays/:replay_id", replayHandler.GetReplay)
				w.POST("/replays/:replay_id/execute", replayHandler.ExecuteReplay)
				w.GET("/replays/:replay_id/results", replayHandler.GetResults)

				// Mocks
				w.GET("/mocks", mockHandler.GetAll)
				w.POST("/mocks/generate", mockHandler.GenerateFromTrace)
				w.PUT("/mocks/:mock_id", mockHandler.Update)
				w.DELETE("/mocks/:mock_id", mockHandler.Delete)

				// Workflows
				w.POST("/workflows", workflowHandler.Create)
				w.POST("/workflows/:workflow_id/execute", workflowHandler.Execute)

				// Environments
				w.GET("/environments", environmentHandler.GetEnvironments)
				w.POST("/environments", environmentHandler.CreateEnvironment)
				w.GET("/environments/:environment_id", environmentHandler.GetEnvironmentVariables)
				w.PUT("/environments/:environment_id", environmentHandler.UpdateEnvironment)
				w.DELETE("/environments/:environment_id", environmentHandler.DeleteEnvironment)
				w.POST("/environments/:environment_id/variables", environmentHandler.AddEnvironmentVariable)
				w.PUT("/environments/:environment_id/variables/:variable_id", environmentHandler.UpdateEnvironmentVariable)
				w.DELETE("/environments/:environment_id/variables/:variable_id", environmentHandler.DeleteEnvironmentVariable)

				// Secrets
				w.POST("/secrets", secretsHandler.Create)
				w.GET("/secrets/:secret_id/value", secretsHandler.GetValue)
				w.POST("/secrets/:secret_id/rotate", secretsHandler.Rotate)

				// Alerts
				w.POST("/alerts/rules", alertHandler.CreateRule)
				w.GET("/alerts/active", alertHandler.GetActiveAlerts)
				w.POST("/alerts/:alert_id/acknowledge", alertHandler.AcknowledgeAlert)

				// Load test
				w.POST("/load-test", loadTestHandler.Create)
			}
		}
	}

	addr := ":" + cfg.Port
	log.Printf("Server starting on %s", addr)
	if err := router.Run(addr); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}