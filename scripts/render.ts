// Genere la video Short (MP4) a partir d'un fichier de donnees quotidien.
//
// Usage :
//   npm run render -- data/day-example.json out/day-1.mp4
//   npm run render -- data/2026-07-09.json
//
// Si le chemin de sortie est omis, il est deduit du numero du jour.
import "dotenv/config";
import { bundle } from "@remotion/bundler";
import { renderMedia, selectComposition } from "@remotion/renderer";
import { readFileSync, mkdirSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import type { DailyData } from "../src/types";

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(__dirname, "..");

export const renderVideo = async (dataPath: string, outPath?: string): Promise<string> => {
  const data = JSON.parse(readFileSync(dataPath, "utf-8")) as DailyData;
  const output = outPath ?? resolve(ROOT, "out", `day-${data.day}.mp4`);
  mkdirSync(dirname(output), { recursive: true });

  console.log(`[render] Bundle du projet Remotion...`);
  const serveUrl = await bundle({
    entryPoint: resolve(ROOT, "src/index.ts"),
    // webpackOverride: (c) => c, // hook si besoin de personnaliser webpack
  });

  console.log(`[render] Selection de la composition (jour ${data.day})...`);
  const composition = await selectComposition({
    serveUrl,
    id: "DailyVideo",
    inputProps: data,
    browserExecutable: process.env.CHROMIUM_PATH || undefined,
  });

  console.log(`[render] Rendu de ${composition.durationInFrames} frames -> ${output}`);
  await renderMedia({
    composition,
    serveUrl,
    codec: "h264",
    outputLocation: output,
    inputProps: data,
    browserExecutable: process.env.CHROMIUM_PATH || undefined,
    // "swangle" = rendu logiciel, fiable sur un serveur sans GPU.
    chromiumOptions: { gl: "swangle" },
  });

  console.log(`[render] OK -> ${output}`);
  return output;
};

// Execution directe en CLI.
const isMain = process.argv[1] && resolve(process.argv[1]) === resolve(fileURLToPath(import.meta.url));
if (isMain) {
  const dataArg = process.argv[2] ?? resolve(ROOT, "data/day-example.json");
  const outArg = process.argv[3];
  renderVideo(resolve(dataArg), outArg ? resolve(outArg) : undefined).catch((err) => {
    console.error(err);
    process.exit(1);
  });
}
