// Publie la video en tant que Short sur YouTube (API Data v3, upload direct du fichier).
//
// Pre-requis (une seule fois) :
//   1. Console Google Cloud -> active "YouTube Data API v3".
//   2. Cree des identifiants OAuth 2.0 (type "Application de bureau").
//   3. Genere un refresh token avec le scope
//        https://www.googleapis.com/auth/youtube.upload
//      (via l'OAuth Playground ou le script d'aide decrit dans le README).
//   4. Renseigne dans .env :
//        YOUTUBE_CLIENT_ID=...
//        YOUTUBE_CLIENT_SECRET=...
//        YOUTUBE_REFRESH_TOKEN=...
import "dotenv/config";
import { google } from "googleapis";
import { createReadStream, readFileSync } from "node:fs";
import { resolve } from "node:path";
import type { DailyData } from "../src/types";
import { buildCaption } from "./caption";

export const publishYouTube = async (videoPath: string, data: DailyData): Promise<string> => {
  const clientId = process.env.YOUTUBE_CLIENT_ID;
  const clientSecret = process.env.YOUTUBE_CLIENT_SECRET;
  const refreshToken = process.env.YOUTUBE_REFRESH_TOKEN;
  if (!clientId || !clientSecret || !refreshToken) {
    throw new Error("YOUTUBE_CLIENT_ID / YOUTUBE_CLIENT_SECRET / YOUTUBE_REFRESH_TOKEN manquants dans .env");
  }

  const oauth2 = new google.auth.OAuth2(clientId, clientSecret);
  oauth2.setCredentials({ refresh_token: refreshToken });
  const youtube = google.youtube({ version: "v3", auth: oauth2 });

  const caption = buildCaption(data);
  const res = await youtube.videos.insert({
    part: ["snippet", "status"],
    requestBody: {
      snippet: {
        title: caption.title.slice(0, 100), // limite YouTube : 100 caracteres
        description: caption.description,
        tags: caption.hashtags.map((h) => h.replace("#", "")),
        categoryId: "24", // Divertissement
      },
      status: {
        privacyStatus: "public",
        selfDeclaredMadeForKids: false,
      },
    },
    media: { body: createReadStream(videoPath) },
  });

  const id = res.data.id ?? "";
  console.log(`[youtube] Publie : https://youtube.com/shorts/${id}`);
  return id;
};

const isMain =
  process.argv[1] && import.meta.url === `file://${process.argv[1].replace(/\\/g, "/")}`;
if (isMain) {
  const dataPath = resolve(process.argv[2] ?? "data/day-example.json");
  const videoPath = resolve(process.argv[3] ?? "out/day-1.mp4");
  const data = JSON.parse(readFileSync(dataPath, "utf-8")) as DailyData;
  publishYouTube(videoPath, data).catch((err) => {
    console.error(err.message ?? err);
    process.exit(1);
  });
}
