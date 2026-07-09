# 💸 Experience « 1$ a des inconnus » — usine a Shorts automatique

Genere **chaque jour** une video verticale (Short) qui montre les DM du jour et le
**total d'argent recolte**, puis la **publie automatiquement** sur YouTube, TikTok
et Instagram.

Le principe : tu demandes 1$ a des inconnus, tu documentes l'experience en video,
et c'est la video (curiosite + partage) qui fait la portee — pas le fait de
contacter les gens en masse.

---

## 🧩 Comment ca marche

```
data/AAAA-MM-JJ.json   ← TOI : tu ecris les DM du jour (5 min)
        │
        ▼
 scripts/run-daily.ts   (orchestrateur)
        │
        ├─ 1. fetch-paypal-total   → recupere le total cumule (API PayPal)
        ├─ 2. render               → genere la video Short (Remotion → MP4)
        └─ 3. publish              → YouTube + TikTok + Instagram
        │
        ▼
     out/day-N.mp4
```

Ce qui est **100% automatique** : le total PayPal, la generation de la video, la
publication. Ce que **toi** tu fournis chaque jour : le texte des DM (voir plus bas).
C'est volontaire — aucune API ne lit tes DM prives, et tu veux de toute facon
choisir/anonymiser ce que tu montres.

---

## 🚀 Installation

Pre-requis : **Node.js 18+**.

```bash
npm install
cp .env.example .env      # puis remplis .env (voir "Configuration" plus bas)
```

Le rendu utilise Chromium. **En local**, laisse `CHROMIUM_PATH` vide dans `.env` :
Remotion telecharge automatiquement son navigateur au premier rendu.

---

## ✍️ Le fichier du jour

Chaque jour, cree `data/AAAA-MM-JJ.json` (copie `data/day-example.json`) :

```json
{
  "day": 1,
  "totalRaised": 0,
  "currencySymbol": "$",
  "goal": 1000,
  "conversations": [
    {
      "personLabel": "Inconnu #1",
      "messages": [
        { "from": "me",   "text": "Salut ! Tu me donnerais 1$ juste pour voir ?" },
        { "from": "them", "text": "mdr c'est quoi l'arnaque" },
        { "from": "me",   "text": "aucune, juste 1$. Lien dans ma bio 🙏" },
        { "from": "them", "text": "ok tiens 😂" }
      ]
    }
  ]
}
```

- `from: "me"` = toi (bulle bleue a droite) · `from: "them"` = l'inconnu (bulle grise a gauche).
- `totalRaised` est **ecrase automatiquement** par le total PayPal (sauf si `SKIP_PAYPAL=1`).
- `personLabel` : garde-le **anonyme** (« Inconnu #3 »). Ne mets jamais le vrai nom
  ou @ des gens sans leur accord — respect de la vie privee.
- Les emojis fonctionnent. 👍

### Tester la video seule

```bash
npm run render -- data/day-example.json out/test.mp4
```

> Astuce : la video n'a **pas de son** (c'est voulu). Ajoute une musique tendance
> directement dans l'app TikTok/Reels au moment de poster — c'est meilleur pour
> l'algorithme. En publication 100% auto, la video sort sans musique.

---

## 🔑 Configuration (.env)

### 1. PayPal — total automatique
1. Va sur https://developer.paypal.com → **Apps & Credentials** → cree une app REST.
2. Dans les fonctionnalites de l'app, **active « Transaction Search »**.
3. Renseigne `PAYPAL_CLIENT_ID`, `PAYPAL_SECRET`, `PAYPAL_ENV=live`,
   `EXPERIMENT_START_DATE` (date de debut) et `CURRENCY` (ex `USD`).

⚠️ **Risque de gel PayPal** : recevoir beaucoup de micro-paiements sans
contrepartie peut declencher les algos anti-fraude (compte limite, fonds bloques
180 jours). Une plateforme de dons (Ko-fi, Buy Me a Coffee…) est plus sure ; tu
pourras brancher son total plus tard a la place de PayPal.

### 2. YouTube — API Data v3
1. Console Google Cloud → active **« YouTube Data API v3 »**.
2. Cree des identifiants **OAuth 2.0** (type « Application de bureau »).
3. Genere un **refresh token** avec le scope
   `https://www.googleapis.com/auth/youtube.upload` (le plus simple :
   [OAuth 2.0 Playground](https://developers.google.com/oauthplayground), en
   cochant « Use your own OAuth credentials »).
4. Renseigne `YOUTUBE_CLIENT_ID`, `YOUTUBE_CLIENT_SECRET`, `YOUTUBE_REFRESH_TOKEN`.

### 3. TikTok — Content Posting API
1. https://developers.tiktok.com → cree une app, ajoute **Content Posting API**
   (scope `video.publish`), obtiens un access token utilisateur.
2. Renseigne `TIKTOK_ACCESS_TOKEN`.
3. `TIKTOK_PRIVACY_LEVEL=SELF_ONLY` **tant que l'app n'est pas auditee** par TikTok
   (la video sort en prive ; tu la rends publique a la main). Apres validation,
   passe a `PUBLIC_TO_EVERYONE` pour du 100% auto public.

### 4. Instagram — Graph API
1. Compte Instagram **PRO** (Business/Createur) relie a une **Page Facebook**.
2. App Meta avec la permission **`instagram_content_publish`** (validation Meta requise).
3. Renseigne `IG_USER_ID`, `IG_ACCESS_TOKEN`.
4. **Instagram n'accepte pas l'upload direct d'un fichier** : il faut une **URL HTTPS
   publique** ou la video est hebergee. Renseigne `VIDEO_PUBLIC_URL` (voir ci-dessous).

#### Heberger la video pour Instagram
Heberge `out/day-N.mp4` a une URL publique (bucket S3/Cloudflare R2/Backblaze,
GitHub Release, etc.) et mets cette URL dans `VIDEO_PUBLIC_URL` avant de lancer le
run. Sans URL publique, Instagram est **ignore** (les autres plateformes marchent).

---

## ▶️ Lancer un run quotidien

```bash
# Utilise data/<date d'aujourd'hui>.json
npm run daily

# Ou un fichier precis
npm run daily -- data/2026-07-09.json
```

Chaque plateforme est independante : si l'une echoue, les autres continuent, et un
resume s'affiche a la fin.

Variables utiles :
- `PUBLISH_TARGETS=youtube,tiktok` → ne publier que sur certaines plateformes.
- `SKIP_PAYPAL=1` → garder le `totalRaised` du fichier (utile pour tester).

---

## ⏰ Automatiser (1 fois par jour)

Sur un serveur/PC allume, ajoute une tache **cron** (ici tous les jours a 18h00) :

```cron
0 18 * * *  cd /chemin/vers/le/projet && /usr/bin/npm run daily >> daily.log 2>&1
```

Il te restera juste a deposer le fichier `data/AAAA-MM-JJ.json` du jour avant l'heure.

---

## 🧪 Ce qui est teste

- ✅ Generation video (intro + compteur anime + bulles de DM + CTA) : **verifiee**,
  rend un MP4 vertical 1080×1920.
- ✅ Orchestrateur (gel des donnees → rendu → resume) : **verifie**.
- ⚙️ Publishers (YouTube/TikTok/Instagram) et PayPal : le code est complet, mais
  ils necessitent **tes** comptes/tokens pour tourner en reel (renseigne `.env`).

---

## 📁 Structure

```
src/
  Root.tsx            Enregistrement de la composition Remotion
  DailyVideo.tsx      Enchaine intro → compteur → conversations → outro
  config.ts           Dimensions, durees, calcul de la duree totale
  types.ts            Modele de donnees (DailyData, Conversation, ChatMessage)
  font.ts / font-loader.ts   Police Montserrat embarquee (offline)
  components/         Background, Intro, MoneyCounter, ChatConversation, Outro
scripts/
  render.ts           Genere le MP4 a partir d'un fichier de donnees
  fetch-paypal-total.ts   Total cumule via l'API PayPal
  caption.ts          Titre / description / hashtags
  publish-youtube.ts  Upload Short YouTube
  publish-tiktok.ts   Upload TikTok
  publish-instagram.ts   Publication Reel Instagram
  run-daily.ts        Orchestrateur quotidien
data/                 Fichiers du jour (tu les crees)
out/                  Videos generees (ignore par git)
```

---

## ⚖️ Rappels importants

- **Respecte la vie privee** : anonymise les DM (pas de vrais noms/@ sans accord).
- **Vise large, pas « les riches »** : pour un modele petit-montant × grand-nombre,
  la portee vient du contenu et du partage, pas du ciblage. On ne spamme personne.
- **Publier automatiquement** doit respecter les CGU de chaque plateforme (comptes
  reels, pas de bots de masse).
