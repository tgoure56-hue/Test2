import { useCurrentFrame, useVideoConfig, spring, interpolate, AbsoluteFill } from "remotion";

// Compteur d'argent qui monte + barre de progression vers l'objectif.
export const MoneyCounter: React.FC<{
  total: number;
  goal: number;
  currencySymbol: string;
}> = ({ total, goal, currencySymbol }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Le compteur monte de 0 jusqu'au total sur ~1.6s.
  const progress = spring({ frame, fps, config: { damping: 200 }, durationInFrames: Math.round(fps * 1.6) });
  const shown = Math.round(interpolate(progress, [0, 1], [0, total]) * 100) / 100;

  const pct = goal > 0 ? Math.min(1, total / goal) : 0;
  const barFill = interpolate(progress, [0, 1], [0, pct]);

  const labelOpacity = interpolate(frame, [0, 12], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  return (
    <AbsoluteFill style={{ justifyContent: "center", alignItems: "center", padding: 80 }}>
      <div style={{ opacity: labelOpacity, color: "#fff", fontSize: 52, fontWeight: 700 }}>
        Total recolte jusqu'ici
      </div>
      <div
        style={{
          marginTop: 20,
          color: "#ffe14d",
          fontSize: 180,
          fontWeight: 900,
          textShadow: "0 10px 40px rgba(0,0,0,0.4)",
          fontVariantNumeric: "tabular-nums",
        }}
      >
        {currencySymbol}
        {shown.toLocaleString("fr-FR", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
      </div>

      <div
        style={{
          marginTop: 60,
          width: 760,
          height: 34,
          borderRadius: 20,
          background: "rgba(255,255,255,0.18)",
          overflow: "hidden",
        }}
      >
        <div
          style={{
            width: `${barFill * 100}%`,
            height: "100%",
            borderRadius: 20,
            background: "linear-gradient(90deg,#39e6a0,#ffe14d)",
          }}
        />
      </div>
      <div style={{ marginTop: 22, color: "#fff", fontSize: 40, fontWeight: 700, opacity: 0.9 }}>
        Objectif : {currencySymbol}
        {goal.toLocaleString("fr-FR")}
      </div>
    </AbsoluteFill>
  );
};
