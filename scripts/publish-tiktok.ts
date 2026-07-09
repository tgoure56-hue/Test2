// Publie la video sur TikTok via la "Content Posting API" (upload direct du fichier).
//
// Pre-requis (une seule fois) :
//   1. Cree une app sur https://developers.tiktok.com et ajoute le produit
//      "Content Posting API" avec le scope video.publish.
//   2. Obtiens un access token utilisateur (OAuth) pour ton compte TikTok.
//   3. Renseigne dans .env :
//        TIKTOK_ACCESS_TOKEN=...
//        TIKTOK_PRIVACY_LEVEL=SELF_ONLY   (obligatoire tant que l'app n'est pas
//                                          auditee ; passe a PUBLIC_TO_EVERYONE
//                                          apres validation par TikTok)
//
// IMPORTANT : tant que ton app n'a pas passe l'audit TikTok, la video est postee
// en prive (SELF_ONLY) ; tu la rends publique manuellement depuis l'app, ou tu
// attends la validation pour publier en public automatiquement.
import "dotenv/config";
import { readFileSync, statSync } from "node:fs";
import { resolve } from "node:path";
import type { DailyData } from "../src/types";
import { buildCaption } from "./caption";

const API = "https://open.tiktokapis.com/v2";

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

export const publishTikTok = async (videoPath: string, data: DailyData): Promise<string> => {
  const token = process.env.TIKTOK_ACCESS_TOKEN;
  if (!token) throw new Error("TIKTOK_ACCESS_TOKEN manquant dans .env");
  const privacy = process.env.TIKTOK_PRIVACY_LEVEL || "SELF_ONLY";

  const caption = buildCaption(data);
  const size = statSync(videoPath).size;

  // 1) Initialisation : on annonce un upload en un seul chunk (fichier entier).
  const initRes = await fetch(`${API}/post/publish/video/init/`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json; charset=UTF-8",
    },
    body: JSON.stringify({
      post_info: {
        title: caption.title,
        privacy_level: privacy,
        disable_comment: false,
        disable_duet: false,
        disable_stitch: false,
      },
      source_info: {
        source: "FILE_UPLOAD",
        video_size: size,
        chunk_size: size,
        total_chunk_count: 1,
      },
    }),
  });
  const initJson = (await initRes.json()) as {
    data?: { publish_id?: string; upload_url?: string };
    error?: { code?: string; message?: string };
  };
  if (!initRes.ok || !initJson.data?.upload_url || !initJson.data?.publish_id) {
    throw new Error(`TikTok init echouee : ${JSON.stringify(initJson.error ?? initJson)}`);
  }
  const { upload_url, publish_id } = initJson.data;

  // 2) Envoi des octets de la video.
  const bytes = readFileSync(videoPath);
  const upRes = await fetch(upload_url, {
    method: "PUT",
    headers: {
      "Content-Type": "video/mp4",
      "Content-Length": String(size),
      "Content-Range": `bytes 0-${size - 1}/${size}`,
    },
    body: bytes,
  });
  if (!upRes.ok) {
    throw new Error(`TikTok upload echoue (${upRes.status}) : ${await upRes.text()}`);
  }

  // 3) Attente de la fin du traitement cote TikTok.
  for (let i = 0; i < 20; i++) {
    await sleep(3000);
    const stRes = await fetch(`${API}/post/publish/status/fetch/`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json; charset=UTF-8",
      },
      body: JSON.stringify({ publish_id }),
    });
    const stJson = (await stRes.json()) as { data?: { status?: string; fail_reason?: string } };
    const status = stJson.data?.status;
    if (status === "PUBLISH_COMPLETE") {
      console.log(`[tiktok] Publie (publish_id ${publish_id}, confidentialite ${privacy})`);
      return publish_id;
    }
    if (status === "FAILED") {
      throw new Error(`TikTok a echoue : ${stJson.data?.fail_reason ?? "raison inconnue"}`);
    }
  }
  console.log(`[tiktok] Envoye (publish_id ${publish_id}) - traitement encore en cours cote TikTok.`);
  return publish_id;
};

const isMain =
  process.argv[1] && import.meta.url === `file://${process.argv[1].replace(/\\/g, "/")}`;
if (isMain) {
  const dataPath = resolve(process.argv[2] ?? "data/day-example.json");
  const videoPath = resolve(process.argv[3] ?? "out/day-1.mp4");
  const data = JSON.parse(readFileSync(dataPath, "utf-8")) as DailyData;
  publishTikTok(videoPath, data).catch((err) => {
    console.error(err.message ?? err);
    process.exit(1);
  });
}
