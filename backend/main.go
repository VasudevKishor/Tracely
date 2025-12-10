package main

import (
    "context"
    "log"
    "time"

    "github.com/gofiber/fiber/v2"
    "github.com/gofiber/fiber/v2/middleware/cors"
    "go.mongodb.org/mongo-driver/mongo"
    "go.mongodb.org/mongo-driver/mongo/options"
)

// Configuration
const PORT = ":8080"
const MONGO_URI = "mongodb://localhost:27017"

// Database Instance
var collection *mongo.Collection

func main() {
    // 1. Connect to MongoDB
    ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
    defer cancel()
    client, err := mongo.Connect(ctx, options.Client().ApplyURI(MONGO_URI))
    if err != nil {
        log.Fatal(err)
    }
    // Create a database named "traceops" and collection "interactions"
    collection = client.Database("traceops").Collection("interactions")
    log.Println("✅ Connected to MongoDB")

    // 2. Setup Server
    app := fiber.New()

    // Enable CORS so Next.js (Port 3000) can talk to Go (Port 8080)
    app.Use(cors.New())

    // 3. Define Routes
    app.Get("/", func(c *fiber.Ctx) error {
        return c.SendString("🚀 TraceOps Backend is Running!")
    })

    app.Post("/api/record", func(c *fiber.Ctx) error {
        // This is where we will receive traffic from the Chrome Extension later
        return c.JSON(fiber.Map{"status": "recorded", "id": "12345"})
    })

    // 4. Start Server
    log.Fatal(app.Listen(PORT))
}