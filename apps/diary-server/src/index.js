import "dotenv/config";
import cors from "cors";
import express from "express";
import rateLimit from "express-rate-limit";
import { authMiddleware } from "./middleware/auth.js";
import { aiRouter } from "./routes/ai.js";

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  message: { error: "Too many requests, please try again later." },
});
app.use(limiter);

app.use(cors());
app.use(express.json({ limit: "50mb" })); // Increase limit for Base64 images

// Health check
app.get("/health", (_req, res) => {
  res.json({ status: "healthy", timestamp: new Date().toISOString() });
});

// AI Proxy Routes (Protected)
app.use("/api/ai", authMiddleware, aiRouter);

// Error handler
app.use((err, _req, res, _next) => {
  console.error(err.stack);
  res.status(500).json({ error: "Internal server error" });
});

// For local development
if (process.env.NODE_ENV !== "production") {
  app.listen(PORT, "0.0.0.0", () => {
    console.log(`🚀 AI Diary Proxy Server running on http://0.0.0.0:${PORT}`);
  });
}

// Export for Firebase Functions
import { onRequest } from "firebase-functions/v2/https";
// Deploy as API endpoint to Seoul region (Asia Northeast3)
export const api = onRequest({ region: "asia-northeast3" }, app);

// Export for Vercel Serverless
export default app;
