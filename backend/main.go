package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
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

	// Initialize handlers
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

	// Setup router
	router := setupRouter(cfg, authService, authHandler, workspaceHandler, collectionHandler,
		requestHandler, traceHandler, monitoringHandler, governanceHandler, settingsHandler,
		replayHandler, mockHandler)

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
	authHandler *handlers.AuthHandler,
	workspaceHandler *handlers.WorkspaceHandler,
	collectionHandler *handlers.CollectionHandler,
	requestHandler *handlers.RequestHandler,
	traceHandler *handlers.TraceHandler,
	monitoringHandler *handlers.MonitoringHandler,
	governanceHandler *handlers.GovernanceHandler,
	settingsHandler *handlers.SettingsHandler,
	replayHandler *handlers.ReplayHandler,
	mockHandler *handlers.MockHandler) *gin.Engine {

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
		MaxAge:           12 * time.Hour,
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
			}

			// User settings routes
			protected.GET("/users/settings", settingsHandler.GetSettings)
			protected.PUT("/users/settings", settingsHandler.UpdateSettings)
		}
	}

	return router
}
