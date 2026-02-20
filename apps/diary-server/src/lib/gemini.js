import { GoogleGenerativeAI } from "@google/generative-ai";

const apiKey = process.env.GEMINI_API_KEY;

if (!apiKey) {
  console.warn("Missing GEMINI_API_KEY environment variable");
}

const genAI = new GoogleGenerativeAI(apiKey || "");

const PROMPTS = {
  en: {
    analyze: `
    ### Task:
    Write a **personal diary entry** inspired by the photo(s) provided and the given additional information. Your goal is to vividly describe the moment captured in the photo(s), incorporating the details from "additional_text" if provided.
    
    ### Rules:
    1. **Follow "additional_text" for Focus**:
       - If "additional_text" describes a person or object in the photo, write from the perspective of someone reflecting on or interacting with that person or object.
       - If "additional_text" is missing or unclear, write the diary entry as yourself, focusing on your own perspective of the photo.
    
    2. **No Guesswork or Invented Details**:
       - Do NOT create names, relationships, backstories, or details not present in the photo(s) or "additional_text."
       - Only describe what is explicitly mentioned in "additional_text" or visible in the photo(s).
    
    3. **Describe the Scene**:
       - Use sensory details (sights, sounds, smells, feelings) to describe what is visible in the photo(s) or aligns with "additional_text."
       - Avoid adding any elements or assumptions not present in the source material.
    
    4. **Express Personal Thoughts and Emotions**:
       - Share genuine feelings or reflections sparked by the photo(s) and "additional_text."
       - Write authentically, as if in a private journal, keeping the tone natural and personal.
    
    5. **Avoid Analysis or Assumptions**:
       - Do NOT analyze or interpret beyond the visible or mentioned details.
       - Stick strictly to the provided context.
    
    6. **One Style ONLY**:
       - Write EXACTLY ONE diary entry matching the specific style requested in "additional_text".
       - DO NOT write multiple versions (e.g., do not output both a normal style and an SNS style).
       - Adapt the length based on the requested style (e.g., SNS: 3-4 sentences with hashtags, normal: 7-9 sentences).

    7. **Remove unrelated words & Strict Weather Constraint**:
       - Do not write unrelated content.
       - If the weather information says "None" or is not provided, DO NOT mention or invent any weather (e.g., sunny, rainy, cold, etc.) under any circumstance.

    8. **No Meta-Text or Headings**:
       - DO NOT write any titles, headings, or markdown headers (e.g., "## SNS Style", "Diary Entry:"). Just output the raw diary content directly.
       `,
  },
  ko: {
    analyze: `
    ### 과제:
    제공된 사진과 추가 정보("additional_text")를 바탕으로 **개인적인 일기**를 작성하세요. 사진 속 순간을 생생하게 묘사하며, "additional_text"에 있는 내용을 포함해 작성하세요.
    
    ### 규칙:
    1. **"additional_text"를 기준으로 작성**:
       - "additional_text"에서 사진 속 인물이나 사물에 대해 설명하고 있다면, 그 인물이나 사물과 관련된 생각이나 느낌을 중심으로 작성하세요.
       - "additional_text"가 없거나 명확하지 않을 경우, 사진을 바라보는 **나 자신**의 시각에서 일기를 작성하세요.
    
    2. **추측이나 창작 금지**:
       - 사진이나 "additional_text"에 없는 이름, 관계, 배경 이야기를 만들지 마세요.
       - "additional_text"와 사진에서 명확히 확인할 수 있는 정보만 사용하세요.
    
    3. **장면 묘사**:
       - 사진에 보이거나 "additional_text"와 일치하는 요소(배경, 인물, 사물, 활동)를 중심으로 묘사하세요.
       - 시각, 소리, 냄새, 감촉 등 감각적인 디테일을 활용하세요.
    
    4. **개인적인 생각과 감정 표현**:
       - 사진과 "additional_text"에서 느낀 감정이나 떠오르는 생각을 진솔하게 적으세요.
       - 사진에 없는 정보를 추가하지 말고, 자연스럽고 진실된 어조로 작성하세요.
    
    5. **분석이나 추측 금지**:
       - 사진과 "additional_text"를 분석하거나 가정하지 말고, 외부적인 해석은 피하세요.
       - 주어진 맥락에서만 글을 작성하세요.
    
    6. **단 하나의 스타일로만 작성 (복수 작성 금지)**:
       - "additional_text"에서 요청한 **정확히 하나의 스타일(예: SNS, 시, 편지 등)**로만 전체 일기를 작성하세요.
       - 절대로 여러 가지 스타일의 버전(예: 일반 스타일 버전 1개, SNS 스타일 버전 1개 등 총 2개 이상)을 동시에 이어서 작성하지 마세요. 오직 단 1개의 일기만 출력해야 합니다.
       - 길이는 요청된 스타일에 맞게 자체적으로 조절하세요 (예: SNS는 해시태그 포함 3~4문장, 일반 일기는 7~9문장 등).

    7. **필요 없는 내용 및 날씨 창작 절대 금지**:
       - 일기의 내용과 관계 없는 내용은 작성하지 마세요.
       - 주어진 데이터에 '날씨' 정보가 없다면("없음"), 절대 일기에 날씨(맑음, 흐림, 비, 더움, 추움 등)를 언급하거나 꾸며내지 마세요. 사진에 날씨가 보여도 언급하지 마세요.

    8. **제목 및 불필요한 서문 작성 금지 (매우 중요)**:
       - 일기 내용 시작 전에 "## SNS 스타일", "## 일반 스타일", "오늘의 일기:" 와 같은 형식적인 마크다운 제목이나 머리말을 절대 작성하지 마세요. 질문자에게 대답하는 말 없이 오직 **순수 일기 본문만 바로 출력**하세요.
       `,
  },
};

/**
 * Generate diary content using Gemini AI
 * @param {Object} params
 * @param {string} params.prompt - User's prompt/instructions
 * @param {string} params.mood - User's mood
 * @param {Object} params.weather - Weather data
 * @param {Array} params.sources - Collected data sources
 * @param {Array<string>} params.images - Base64 encoded images
 * @param {string} params.lang - Language ('ko' or 'en')
 * @returns {Promise<string>} Generated diary content
 */
export async function generateDiary({ prompt, mood, weather, sources, images, lang = "ko" }) {
  // Using gemini-2.5-flash as requested (Note: ensure this model name is supported by your API key)
  const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash-lite" });

  const basePrompt = PROMPTS[lang]?.analyze || PROMPTS.ko.analyze;

  const contextText = `
[하루 기록 데이터]
기분: ${mood || "선택 안 함"}
${weather ? `날씨: ${weather.condition}, ${weather.temp}°C` : "날씨: 없음 (본문에 날씨 작성 금지)"}
수집된 정보:
${sources?.map((s) => `- [${s.type}] ${s.contentPreview || s.content_preview}`).join("\n") || "데이터 없음"}

추가 정보(additional_text):
${prompt || "오늘 하루에 대한 특별한 요청사항은 없습니다."}
`;

  const parts = [{ text: basePrompt }, { text: contextText }];

  if (images && images.length > 0) {
    for (const base64Data of images) {
      if (base64Data) {
        parts.push({
          inlineData: {
            mimeType: "image/jpeg",
            data: base64Data.split(",").pop(),
          },
        });
      }
    }
  }

  try {
    const result = await model.generateContent(parts);
    const response = await result.response;
    return response.text();
  } catch (error) {
    console.error("Gemini Generation Error:", error);
    throw error;
  }
}
