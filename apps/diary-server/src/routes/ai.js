import { Router } from "express";
import { generateDiary } from "../lib/gemini.js";
import { getUserInfo } from "../lib/api.js";

export const aiRouter = Router();

// Generate diary content using AI
aiRouter.post("/generate", async (req, res) => {
  try {
    const { prompt, mood, weather, sources, images } = req.body;

    // === DEV_BYPASS_START ===
    // Check Pro status (skip in development mode)
    const isDev = process.env.NODE_ENV !== 'production';
    if (!isDev) {
    // === DEV_BYPASS_END ===
      const userInfo = await getUserInfo(req.user.user_id, req.headers.authorization.split(" ")[1]);
      if (!userInfo || !userInfo.is_pro) {
        return res.status(403).json({ error: "Pro subscription required for AI generation" });
      }
    // === DEV_BYPASS_START ===
    }
    // === DEV_BYPASS_END ===

    // Generate diary content using Gemini
    const content = await generateDiary({ prompt, mood, weather, sources, images });

    res.json({ content });
  } catch (error) {
    console.error("Error generating diary:", error);
    res.status(500).json({ error: "Failed to generate diary via Gemini" });
  }
});

// Regenerate diary content
aiRouter.post("/regenerate", async (req, res) => {
  try {
    const { prompt, mood, weather, sources, previous_content, images } = req.body;

    // Generate with context of previous content
    const enhancedPrompt = previous_content 
      ? `이전 내용을 참고하되 다른 방식으로 작성해주세요. 이전 내용: ${previous_content}\n\n새 요청: ${prompt}`
      : prompt;

    // === DEV_BYPASS_START ===
    // Check Pro status (skip in development mode)
    const isDev = process.env.NODE_ENV !== 'production';
    if (!isDev) {
    // === DEV_BYPASS_END ===
      const userInfo = await getUserInfo(req.user.user_id, req.headers.authorization.split(" ")[1]);
      if (!userInfo || !userInfo.is_pro) {
        return res.status(403).json({ error: "Pro subscription required for AI generation" });
      }
    // === DEV_BYPASS_START ===
    }
    // === DEV_BYPASS_END ===

    const content = await generateDiary({ 
      prompt: enhancedPrompt, 
      mood, 
      weather, 
      sources,
      images
    });

    res.json({ content });
  } catch (error) {
    console.error("Error regenerating diary:", error);
    res.status(500).json({ error: "Failed to regenerate diary via Gemini" });
  }
});
