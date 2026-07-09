import { useCurrentFrame, useVideoConfig, spring, interpolate, AbsoluteFill } from "remotion";

// Ecran d'accroche : "JOUR N" + phrase choc.
export const Intro: React.FC<{ day: number }> = ({ day }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const pop = spring({ frame, fps, config: { damping: 12, mass: 0.6 } });
  const scale = interpolate(pop, [0, 1], [0.6, 1]);
  const subOpacity = interpolate(frame, [12, 28], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  return (
    <AbsoluteFill
      style={{
        justifyContent: "center",
        alignItems: "center",
        padding: 80,
        textAlign: "center",
      }}
    >
      <div
        style={{
          transform: `scale(${scale})`,
          background: "rgba(255,255,255,0.14)",
          border: "2px solid rgba(255,255,255,0.35)",
          borderRadius: 40,
          padding: "18px 44px",
          color: "#fff",
          fontSize: 64,
          fontWeight: 800,
          letterSpacing: 2,
        }}
      >
        JOUR {day}
      </div>
      <div
        style={{
          marginTop: 60,
          opacity: subOpacity,
          color: "#fff",
          fontSize: 88,
          fontWeight: 900,
          lineHeight: 1.1,
          textShadow: "0 8px 30px rgba(0,0,0,0.35)",
        }}
      >
        J'ai demande <span style={{ color: "#ffe14d" }}>1$</span>
        <br />a des inconnus 😳
      </div>
    </AbsoluteFill>
  );
};
