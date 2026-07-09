// Orchestrateur quotidien : recupere le total PayPal, genere la video du jour,
// puis publie sur YouTube, TikTok et Instagram. Chaque etape de publication est
// independante : si une plateforme echoue, les autres continuent.
//
// Usage :
//   npm run daily                       # utilise data/<AAAA-MM-JJ>.json (aujourd'hui)
//   npm run daily -- data/2026-07-09.json
//
// Variables .env utiles (voir .env.example) :
//   PUBLISH_TARGETS=youtube,tiktok,instagram   (par defaut : les 3)
//   VIDEO_PUBLIC_URL=https://.../day-N.mp4      (requis pour Instagram)
//   SKIP_PAYPAL=1                                (garder le total du fichier)
import "dotenv/config";
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import type { DailyData } from "../src/types";
import { renderVideo } from "./render";
import { fetchPaypalTotal } from "./fetch-paypal-total";
import { publishYouTube } from "./publish-youtube";
import { publishTikTok } from "./publish-tiktok";
import { publishInstagram } from "./publish-instagram";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");

const todayFile = (): string => {
  const d = new Date();
  const s = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(
    d.getDate()
  ).padStart(2, "0")}`;
  return resolve(ROOT, "data", `${s}.json`);
};

const main = async () => {
  const dataPath = resolve(process.argv[2] ?? todayFile());
  console.log(`\n=== Experience 1$ - run du ${new Date().toISOString()} ===`);
  console.log(`[data] Fichier : ${dataPath}`);
  const data = JSON.parse(readFileSync(dataPath, "utf-8")) as DailyData;

  // 1) Total PayPal (automatique).
  if (process.env.SKIP_PAYPAL === "1") {
    console.log(`[paypal] Ignore (SKIP_PAYPAL=1). Total du fichier : ${data.totalRaised}`);
  } else {
    try {
      const total = await fetchPaypalTotal();
      data.totalRaised = total;
      console.log(`[paypal] Total recupere : ${data.currencySymbol}${total.toFixed(2)}`);
    } catch (err) {
      console.warn(`[paypal] Echec, on garde le total du fichier (${data.totalRaised}). ${(err as Error).message}`);
    }
  }

  // On fige les donnees du jour (avec le total a jour) pour le rendu.
  mkdirSync(resolve(ROOT, "out"), { recursive: true });
  const frozen = resolve(ROOT, "out", `day-${data.day}-data.json`);
  writeFileSync(frozen, JSON.stringify(data, null, 2));

  // 2) Rendu de la video.
  const videoPath = await renderVideo(frozen, resolve(ROOT, "out", `day-${data.day}.mp4`));

  // 3) Publications.
  const targets = (process.env.PUBLISH_TARGETS ?? "youtube,tiktok,instagram")
    .split(",")
    .map((s) => s.trim().toLowerCase())
    .filter(Boolean);

  const results: Record<string, string> = {};

  if (targets.includes("youtube")) {
    try {
      results.youtube = await publishYouTube(videoPath, data);
    } catch (err) {
      results.youtube = `ECHEC: ${(err as Error).message}`;
      console.error(`[youtube] ${results.youtube}`);
    }
  }

  if (targets.includes("tiktok")) {
    try {
      results.tiktok = await publishTikTok(videoPath, data);
    } catch (err) {
      results.tiktok = `ECHEC: ${(err as Error).message}`;
      console.error(`[tiktok] ${results.tiktok}`);
    }
  }

  if (targets.includes("instagram")) {
    const publicUrl = process.env.VIDEO_PUBLIC_URL ?? "";
    if (!publicUrl) {
      results.instagram = "IGNORE: aucune URL publique (VIDEO_PUBLIC_URL). Voir README.";
      console.warn(`[instagram] ${results.instagram}`);
    } else {
      try {
        results.instagram = await publishInstagram(publicUrl, data);
      } catch (err) {
        results.instagram = `ECHEC: ${(err as Error).message}`;
        console.error(`[instagram] ${results.instagram}`);
      }
    }
  }

  console.log(`\n=== Resume ===`);
  console.log(`Video : ${videoPath}`);
  for (const [k, v] of Object.entries(results)) console.log(`${k.padEnd(10)} -> ${v}`);
  console.log(`===============\n`);
};

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
