// Constantes de la video et calcul de la duree en fonction du contenu.
import type { DailyData } from "./types";

export const FPS = 30;
export const WIDTH = 1080;
export const HEIGHT = 1920;

// Duree (en secondes) de chaque segment.
export const INTRO_SECONDS = 2.2;
export const COUNTER_SECONDS = 3.0;
export const OUTRO_SECONDS = 2.5;
// Temps d'apparition par message de DM.
export const PER_MESSAGE_SECONDS = 1.15;
// Petit sas entre deux conversations.
export const PER_CONVO_GAP_SECONDS = 0.6;

export const countMessages = (data: DailyData): number =>
  data.conversations.reduce((n, c) => n + c.messages.length, 0);

// Duree totale de la video, en frames, calculee a partir des donnees.
// Duree (frames) d'une conversation : une bulle par message + un sas de lecture.
export const convoDurationInFrames = (messageCount: number): number =>
  Math.round((messageCount * PER_MESSAGE_SECONDS + PER_CONVO_GAP_SECONDS) * FPS);

export const computeDurationInFrames = (data: DailyData): number => {
  const intro = Math.round(INTRO_SECONDS * FPS);
  const counter = Math.round(COUNTER_SECONDS * FPS);
  const outro = Math.round(OUTRO_SECONDS * FPS);
  const convos = data.conversations.reduce(
    (n, c) => n + convoDurationInFrames(c.messages.length),
    0
  );
  return intro + counter + convos + outro;
};
