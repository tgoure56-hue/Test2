# 🌑 VERSION NOIRE — mini-RPG de créatures dans le navigateur

Un petit RPG de capture de créatures **jouable directement dans Chrome** (ou tout autre
navigateur), dans l'esprit de Pokémon Version Noire : exploration en vue de dessus,
hautes herbes, combats au tour par tour, capture, évolutions, dresseurs… le tout dans
**un seul fichier `index.html`**, sans aucune dépendance.

> Hommage non officiel : toutes les créatures, sprites pixel-art, noms et musiques
> sont des créations originales (aucun élément protégé de Nintendo / Game Freak).

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
| Entrée | Menu pause (équipe, sac, sauvegarde) |
| Échap / X | Annuler |
| M | Couper / remettre la musique |

La partie se **sauvegarde** dans le navigateur (menu pause → SAUVER, plus
sauvegarde auto après les combats et les soins).

## 🗺️ Le jeu

- **3 starters** au choix : Pyrouf 🔥, Aquanou 💧, Verdylis 🌿 — qui **évoluent au niveau 11**
- **13 créatures** originales en pixel-art, 7 types avec table des forces/faiblesses
- **Bourg Sépia** (clinique de soins), **Route 1** et **Lac Onyx** à explorer
- Combats au tour par tour : attaques, critiques, efficacité des types, XP, montées
  de niveau, apprentissage d'attaques
- **Capture** : affaiblis une créature sauvage puis lance une Capsule
- Ton rival **Léo**, la dresseuse **Zoé**, et une **légende** qui rôde sur la rive
  nord du lac quand tu auras prouvé ta valeur…
- Musique et bruitages chiptune (WebAudio)

## ✅ Qualité

Le jeu est couvert par des tests automatisés headless qui jouent de vraies parties :
intro et choix du starter, rencontres sauvages, évolution en plein combat, victoire
ET défaite (K.O. général → retour à la clinique), duel multi-créatures, capture
réussie et ratée, équipe pleine (envoi au labo), soins, sauvegarde/rechargement
fidèle, et toutes les opérations de menus.

**Simplifications volontaires** par rapport aux jeux dont il s'inspire : pas de PP
sur les attaques, pas de statuts (poison, paralysie…), pas d'attaques de soutien ni
de talents/objets tenus, et un PC simplifié (les captures en surplus sont gardées au
labo). Tout le reste du cœur de jeu est là.

Bonne aventure, dresseur ! 🖤
