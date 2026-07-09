// Police Montserrat embarquee (offline, identique sur toutes les machines).
// Les imports CSS @fontsource declarent les @font-face. Le chargement effectif
// des glyphes avant capture est gere par le hook useFontsReady (voir font-loader.ts),
// appele DANS la composition : chaque page de rendu a ainsi son propre handle
// delayRender, ce qui est indispensable pour un rendu multi-frames concurrent.
import "@fontsource/montserrat/latin-400.css";
import "@fontsource/montserrat/latin-600.css";
import "@fontsource/montserrat/latin-700.css";
import "@fontsource/montserrat/latin-800.css";
import "@fontsource/montserrat/latin-900.css";
import "@fontsource/montserrat/latin-ext-400.css";
import "@fontsource/montserrat/latin-ext-600.css";
import "@fontsource/montserrat/latin-ext-700.css";
import "@fontsource/montserrat/latin-ext-800.css";
import "@fontsource/montserrat/latin-ext-900.css";

export const FONT_FAMILY =
  'Montserrat, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif';

export const FONT_WEIGHTS = ["400", "600", "700", "800", "900"] as const;
