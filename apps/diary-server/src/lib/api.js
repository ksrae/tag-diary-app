import axios from "axios";

/**
 * Utility to fetch user info from the main API
 */
export const getUserInfo = async (userId, token) => {
  const MAIN_API_URL = process.env.MAIN_API_URL || "http://localhost:8000";
  
  try {
    const response = await axios.get(`${MAIN_API_URL}/api/users/me`, {
      headers: {
        Authorization: `Bearer ${token}`
      },
      timeout: 5000, // 5 second timeout
    });
    return response.data;
  } catch (error) {
    console.error("Failed to fetch user info from main API:", error.message);
    return null;
  }
};
