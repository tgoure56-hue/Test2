// Recupere automatiquement le total cumule recu sur PayPal depuis le debut de
// l'experience, via l'API "Transaction Search".
//
// Pre-requis (a faire une fois sur https://developer.paypal.com) :
//   1. Cree une app REST -> tu obtiens un Client ID et un Secret.
//   2. Dans les fonctionnalites de l'app, ACTIVE "Transaction Search".
//   3. Renseigne dans .env :
//        PAYPAL_CLIENT_ID=...
//        PAYPAL_SECRET=...
//        PAYPAL_ENV=live            (ou "sandbox" pour tester)
//        EXPERIMENT_START_DATE=2026-07-09
//        CURRENCY=USD               (optionnel : ne compter que cette devise)
//
// Note : l'API ne permet qu'une fenetre de 31 jours max par requete ; on boucle
// donc mois par mois depuis EXPERIMENT_START_DATE jusqu'a aujourd'hui.
import "dotenv/config";

const API_BASE =
  (process.env.PAYPAL_ENV ?? "live") === "sandbox"
    ? "https://api-m.sandbox.paypal.com"
    : "https://api-m.paypal.com";

const getAccessToken = async (): Promise<string> => {
  const id = process.env.PAYPAL_CLIENT_ID;
  const secret = process.env.PAYPAL_SECRET;
  if (!id || !secret) {
    throw new Error("PAYPAL_CLIENT_ID / PAYPAL_SECRET manquants dans .env");
  }
  const auth = Buffer.from(`${id}:${secret}`).toString("base64");
  const res = await fetch(`${API_BASE}/v1/oauth2/token`, {
    method: "POST",
    headers: {
      Authorization: `Basic ${auth}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: "grant_type=client_credentials",
  });
  if (!res.ok) {
    throw new Error(`Auth PayPal echouee (${res.status}) : ${await res.text()}`);
  }
  const json = (await res.json()) as { access_token: string };
  return json.access_token;
};

// Formate une date en ISO8601 avec fuseau, exige par l'API (ex 2026-07-09T00:00:00-0000).
const iso = (d: Date): string => d.toISOString().replace(".000Z", "-0000");

// Genere les bornes de fenetres de 31 jours entre start et end.
const windows = (start: Date, end: Date): Array<[Date, Date]> => {
  const out: Array<[Date, Date]> = [];
  let cursor = new Date(start);
  while (cursor < end) {
    const next = new Date(cursor);
    next.setDate(next.getDate() + 31);
    out.push([new Date(cursor), next < end ? next : end]);
    cursor = next;
  }
  return out;
};

type TxnPage = {
  transaction_details?: Array<{
    transaction_info?: {
      transaction_status?: string;
      transaction_amount?: { value?: string; currency_code?: string };
    };
  }>;
  total_pages?: number;
};

const fetchWindowTotal = async (
  token: string,
  start: Date,
  end: Date,
  currency?: string
): Promise<number> => {
  let total = 0;
  let page = 1;
  let totalPages = 1;
  do {
    const params = new URLSearchParams({
      start_date: iso(start),
      end_date: iso(end),
      fields: "transaction_info",
      page_size: "500",
      page: String(page),
    });
    const res = await fetch(`${API_BASE}/v1/reporting/transactions?${params}`, {
      headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
    });
    if (!res.ok) {
      throw new Error(`Transaction Search echouee (${res.status}) : ${await res.text()}`);
    }
    const json = (await res.json()) as TxnPage;
    totalPages = json.total_pages ?? 1;
    for (const t of json.transaction_details ?? []) {
      const info = t.transaction_info;
      const amount = Number(info?.transaction_amount?.value ?? "0");
      const code = info?.transaction_amount?.currency_code;
      // On ne compte que les paiements RECUS et finalises (montant positif, statut "S").
      const okStatus = info?.transaction_status === "S";
      const okCurrency = !currency || code === currency;
      if (okStatus && okCurrency && amount > 0) total += amount;
    }
    page += 1;
  } while (page <= totalPages);
  return total;
};

export const fetchPaypalTotal = async (): Promise<number> => {
  const startStr = process.env.EXPERIMENT_START_DATE;
  if (!startStr) throw new Error("EXPERIMENT_START_DATE manquant dans .env (ex 2026-07-09)");
  const start = new Date(`${startStr}T00:00:00Z`);
  const end = new Date();
  const token = await getAccessToken();
  const currency = process.env.CURRENCY?.trim() || undefined;

  let total = 0;
  for (const [ws, we] of windows(start, end)) {
    total += await fetchWindowTotal(token, ws, we, currency);
  }
  return Math.round(total * 100) / 100;
};

const isMain =
  process.argv[1] &&
  import.meta.url === `file://${process.argv[1].replace(/\\/g, "/")}`;
if (isMain) {
  fetchPaypalTotal()
    .then((t) => console.log(t.toFixed(2)))
    .catch((err) => {
      console.error(err.message ?? err);
      process.exit(1);
    });
}
