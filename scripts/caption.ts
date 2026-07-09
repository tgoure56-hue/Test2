// Construit le titre, la description et les hashtags de la publication a partir
// des donnees du jour. Utilise par les 3 publishers.
import type { DailyData } from "../src/types";

export type Caption = {
  title: string;
  description: string;
  hashtags: string[];
};

export const buildCaption = (data: DailyData): Caption => {
  const total = `${data.currencySymbol}${data.totalRaised.toLocaleString("fr-FR", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  })}`;

  const title = `Jour ${data.day} - j'ai demande 1$ a des inconnus (total ${total}) #Shorts`;

  const hashtags = [
    "#experience",
    "#1dollar",
    "#challenge",
    "#argent",
    "#viral",
    "#pourtoi",
    "#fyp",
    "#Shorts",
  ];

  const description = [
    `Jour ${data.day} de l'experience : je demande 1$ a des inconnus, juste pour voir.`,
    `Total recolte jusqu'ici : ${total} / objectif ${data.currencySymbol}${data.goal.toLocaleString("fr-FR")}.`,
    ``,
    `Tu veux faire partie de l'experience ? Le lien est dans ma bio 👀`,
    ``,
    hashtags.join(" "),
  ].join("\n");

  return { title, description, hashtags };
};
