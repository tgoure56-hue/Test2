# 🌑 VERSION NOIRE — Édition Complète

Un RPG de capture de créatures **complet et jouable dans le navigateur** (Chrome,
Firefox…), dans l'esprit des grands jeux du genre : exploration, hautes herbes,
combats au tour par tour, capture, évolutions, **8 arènes**, une **Ligue** et son
Champion, deux **légendaires** en post-game… le tout dans **un seul fichier
`index.html`**, sans aucune dépendance.

> Hommage non officiel : toutes les créatures, sprites pixel-art, noms, cartes et
> musiques sont des créations originales (aucun élément protégé de Nintendo / Game Freak).

## ▶️ Comment jouer

**Option 1 — en local (le plus simple)**
1. Télécharge le fichier [`index.html`](index.html) (bouton *Download raw file* sur GitHub).
2. Double-clique dessus : le jeu s'ouvre dans ton navigateur. C'est tout.

**Option 2 — GitHub Pages**
Active *Settings → Pages → Deploy from branch* sur ce dépôt, et le jeu sera jouable
en ligne à l'adresse fournie par GitHub.

## 🎮 Contrôles

| Touche | Action |
|---|---|
| Flèches / ZQSD / WASD | Se déplacer |
| E / Espace | Parler, valider |
| Entrée | Menu (équipe, sac, carnet, badges, sauvegarde) |
| Échap / X | Annuler |
| M | Couper / remettre la musique |

La partie se **sauvegarde** dans le navigateur (menu → SAUVER, plus sauvegarde
automatique après combats, soins et achats).

## 🗺️ L'aventure

- **39 créatures** originales en pixel-art, avec **lignées d'évolution** (jusqu'au niveau 60)
- **11 types** (Feu, Eau, Plante, Électrik, Vol, Sol, Normal, Glace, Roche, Spectre, Ténèbres)
  avec table complète des forces/faiblesses/immunités
- **Statuts de combat** : poison, brûlure, paralysie — et les objets pour les soigner
- **14 zones** : Bourg Sépia, Route 1, Villeflore, Forêt Murmure, Roche-Bourg,
  Grotte Écho, Port-Azur, le Grand Pont, Voltcité, Plaines Dorées, Désert Ocre,
  Mont Givre, Tour Sombre, Volcan Braise, Route Victoire… chacune avec son ambiance
  visuelle, ses créatures sauvages et ses dresseurs
- **8 arènes** et leurs champions (badges Sève, Roc, Vague, Volt, Dune, Flocon,
  Spectre, Magma) — chaque badge ouvre la route suivante
- **La Ligue** : 4 Maîtres à la suite, puis le Champion… une vieille connaissance
- Ton rival **Léo** (3 affrontements), la **gardienne Zoé**, et l'**Équipe Ombre**
  qui complote pour réveiller la légende du Lac Onyx
- **Économie** : gagne des ₽ contre les dresseurs, dépense-les en boutique
  (Capsules, Potions, Super Potions, Guérisons, Bonbons Rares)
- **Boîte PC** dans chaque clinique pour gérer plus de 6 créatures
- **Carnet** des créatures vues/capturées (complétion du « dex »)
- **Post-game** : le sceau du Lac Onyx se brise (NOCTYRAN niv. 50) et une lumière
  plane sur le Mont Givre (AURYON niv. 50). Captureras-tu les deux légendes ?
- Musique chiptune et bruitages (WebAudio), sprites et décors 100 % faits main

## ✅ Qualité

Le jeu est couvert par **4 bancs de tests automatisés headless** qui jouent de
vraies parties : intro, évolutions en combat, victoires ET défaites (K.O. général),
duels multi-créatures, capture réussie/ratée, équipe pleine, gardes à badges,
arènes, boutique, Boîte PC, carnet, Champion, post-game et sauvegarde/rechargement
à l'identique. Le rendu visuel a été vérifié écran par écran dans un vrai Chromium.
Un auto-test interne valide en outre les données (39 sprites 16×16, tables de types,
courbes d'XP) et **l'atteignabilité de chaque lieu** par parcours en largeur.

**Simplifications assumées** par rapport aux jeux dont il s'inspire : pas de PP sur
les attaques, pas de talents ni d'objets tenus, pas de reproduction/échanges, et des
zones plus compactes. Tout le reste du cœur de jeu est là.

Bonne aventure, dresseur ! 🖤
