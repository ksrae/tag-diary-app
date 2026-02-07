import "dotenv/config";
import express from "express";
import cors from "cors";
import { aiRouter } from "./routes/ai.js";

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json({ limit: '50mb' })); // Increase limit for Base64 images

// Health check
app.get("/health", (req, res) => {
  res.json({ status: "healthy", timestamp: new Date().toISOString() });
});

// AI AI Proxy Routes
app.use("/api/ai", aiRouter);

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: "Internal server error" });
});

// For local development
if (process.env.NODE_ENV !== 'production') {
  app.listen(PORT, "0.0.0.0", () => {
    console.log(`🚀 AI Diary Proxy Server running on http://0.0.0.0:${PORT}`);
  });
}

// Export for Vercel Serverless
export default app;
