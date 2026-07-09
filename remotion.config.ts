import { Config } from "@remotion/cli/config";

// Remotion a besoin d'un navigateur Chromium pour le rendu.
// Sur ce serveur, on pointe vers le Chromium deja installe.
// En local, laisse vide : Remotion telechargera son propre navigateur.
const chromium = process.env.CHROMIUM_PATH;
if (chromium) {
  Config.setBrowserExecutable(chromium);
}

Config.setVideoImageFormat("jpeg");
Config.setOverwriteOutput(true);
Config.setConcurrency(1);
