// Publie la video en Reel sur Instagram via la Graph API.
//
// Pre-requis (une seule fois) :
//   1. Compte Instagram PRO (Business ou Createur) relie a une Page Facebook.
//   2. App Meta (https://developers.facebook.com) avec la permission
//      "instagram_content_publish" (necessite une validation Meta).
//   3. Renseigne dans .env :
//        IG_USER_ID=...          (identifiant du compte Instagram pro)
//        IG_ACCESS_TOKEN=...     (token longue duree)
//        IG_API_VERSION=v21.0    (optionnel)
//
// CONTRAINTE IMPORTANTE : Instagram ne permet PAS d'envoyer le fichier
// directement. Il faut lui fournir une URL HTTPS PUBLIQUE ou la video est
// hebergee (bucket S3/Cloud, etc.). C'est pourquoi ce script recoit l'URL
// publique en argument. Voir le README (section "Heberger la video pour Instagram").
import "dotenv/config";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import type { DailyData } from "../src/types";
import { buildCaption } from "./caption";

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

export const publishInstagram = async (
  publicVideoUrl: string,
  data: DailyData
): Promise<string> => {
  const userId = process.env.IG_USER_ID;
  const token = process.env.IG_ACCESS_TOKEN;
  const version = process.env.IG_API_VERSION || "v21.0";
  if (!userId || !token) throw new Error("IG_USER_ID / IG_ACCESS_TOKEN manquants dans .env");
  if (!publicVideoUrl) throw new Error("URL publique de la video manquante (voir README).");

  const base = `https://graph.facebook.com/${version}`;
  const caption = buildCaption(data);

  // 1) Creation du conteneur media (type REELS).
  const createParams = new URLSearchParams({
    media_type: "REELS",
    video_url: publicVideoUrl,
    caption: caption.description,
    access_token: token,
  });
  const createRes = await fetch(`${base}/${userId}/media`, { method: "POST", body: createParams });
  const createJson = (await createRes.json()) as { id?: string; error?: { message?: string } };
  if (!createRes.ok || !createJson.id) {
    throw new Error(`Instagram: creation du media echouee : ${JSON.stringify(createJson.error ?? createJson)}`);
  }
  const creationId = createJson.id;

  // 2) Attente que le conteneur soit pret (Instagram telecharge + encode la video).
  for (let i = 0; i < 30; i++) {
    await sleep(4000);
    const stRes = await fetch(
      `${base}/${creationId}?fields=status_code&access_token=${encodeURIComponent(token)}`
    );
    const stJson = (await stRes.json()) as { status_code?: string };
    if (stJson.status_code === "FINISHED") break;
    if (stJson.status_code === "ERROR") throw new Error("Instagram: encodage du media en erreur.");
    if (i === 29) throw new Error("Instagram: le media n'est pas pret apres 2 min.");
  }

  // 3) Publication.
  const pubParams = new URLSearchParams({ creation_id: creationId, access_token: token });
  const pubRes = await fetch(`${base}/${userId}/media_publish`, { method: "POST", body: pubParams });
  const pubJson = (await pubRes.json()) as { id?: string; error?: { message?: string } };
  if (!pubRes.ok || !pubJson.id) {
    throw new Error(`Instagram: publication echouee : ${JSON.stringify(pubJson.error ?? pubJson)}`);
  }

  console.log(`[instagram] Reel publie (id ${pubJson.id})`);
  return pubJson.id;
};

const isMain =
  process.argv[1] && import.meta.url === `file://${process.argv[1].replace(/\\/g, "/")}`;
if (isMain) {
  const publicUrl = process.argv[2] ?? process.env.VIDEO_PUBLIC_URL ?? "";
  const dataPath = resolve(process.argv[3] ?? "data/day-example.json");
  const data = JSON.parse(readFileSync(dataPath, "utf-8")) as DailyData;
  publishInstagram(publicUrl, data).catch((err) => {
    console.error(err.message ?? err);
    process.exit(1);
  });
}
