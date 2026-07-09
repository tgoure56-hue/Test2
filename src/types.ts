// Modele de donnees pour une video quotidienne.

export type ChatMessage = {
  // "me" = toi (bulle a droite), "them" = l'inconnu (bulle a gauche)
  from: "me" | "them";
  text: string;
};

export type Conversation = {
  // Etiquette anonyme affichee en haut de la conversation (ex: "Inconnu #3")
  personLabel: string;
  messages: ChatMessage[];
};

export type DailyData = {
  day: number; // numero du jour de l'experience
  totalRaised: number; // total cumule recolte (rempli automatiquement depuis PayPal)
  currencySymbol: string; // ex "$" ou "€"
  goal: number; // objectif affiche dans la barre de progression
  conversations: Conversation[];
};

export const DEFAULT_DATA: DailyData = {
  day: 1,
  totalRaised: 0,
  currencySymbol: "$",
  goal: 1000,
  conversations: [
    {
      personLabel: "Inconnu #1",
      messages: [
        { from: "me", text: "Salut ! Petite experience : tu me donnerais 1$ juste pour voir ? 😅" },
        { from: "them", text: "mdr c'est quoi l'arnaque" },
        { from: "me", text: "aucune, juste 1$, promis. Lien dans ma bio 🙏" },
        { from: "them", text: "ok tiens 😂" },
      ],
    },
  ],
};
