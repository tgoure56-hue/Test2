import { useCurrentFrame, useVideoConfig, spring, interpolate, AbsoluteFill } from "remotion";

// Appel a l'action final : "Lien en bio pour participer".
export const Outro: React.FC<{ currencySymbol: string }> = ({ currencySymbol }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const pop = spring({ frame, fps, config: { damping: 12 } });
  const scale = interpolate(pop, [0, 1], [0.7, 1]);
  const pulse = 1 + 0.04 * Math.sin((frame / fps) * 6);

  return (
    <AbsoluteFill style={{ justifyContent: "center", alignItems: "center", padding: 90, textAlign: "center" }}>
      <div style={{ transform: `scale(${scale})`, color: "#fff", fontSize: 92, fontWeight: 900, lineHeight: 1.15 }}>
        Tu participes ?
      </div>
      <div style={{ marginTop: 40, color: "#fff", fontSize: 58, fontWeight: 700, opacity: 0.95 }}>
        Juste {currencySymbol}1 pour faire partie
        <br />de l'experience 👀
      </div>
      <div
        style={{
          marginTop: 70,
          transform: `scale(${pulse})`,
          background: "#ffe14d",
          color: "#2b1055",
          fontSize: 60,
          fontWeight: 900,
          padding: "26px 60px",
          borderRadius: 50,
          boxShadow: "0 15px 45px rgba(0,0,0,0.35)",
        }}
      >
        👉 Lien en bio
      </div>
    </AbsoluteFill>
  );
};
