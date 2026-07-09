import { useEffect, useState } from "react";
import { continueRender, delayRender } from "remotion";
import { FONT_WEIGHTS } from "./font";

// Garantit que les glyphes Montserrat sont charges avant que Remotion ne capture
// la frame. Appele dans la composition -> un handle delayRender par page de rendu
// (compatible avec le rendu concurrent). Un filet de securite libere le rendu
// meme si le chargement des polices ne se resout pas.
export const useFontsReady = (): void => {
  const [handle] = useState(() => delayRender("Chargement de la police Montserrat"));

  useEffect(() => {
    let cleared = false;
    const clear = () => {
      if (!cleared) {
        cleared = true;
        continueRender(handle);
      }
    };

    const fonts = (document as unknown as { fonts?: FontFaceSet }).fonts;
    if (fonts) {
      Promise.all(FONT_WEIGHTS.map((w) => fonts.load(`${w} 48px "Montserrat"`)))
        .then(clear)
        .catch(clear);
    } else {
      clear();
    }

    // Filet de securite : ne jamais bloquer le rendu plus de 8s pour les polices.
    const safety = setTimeout(clear, 8000);
    return () => clearTimeout(safety);
  }, [handle]);
};
