import { AbsoluteFill, useCurrentFrame, interpolate } from "remotion";

// Fond degrade anime + quelques "blobs" flous qui bougent lentement.
export const Background: React.FC = () => {
  const frame = useCurrentFrame();
  const shift = interpolate(frame % 240, [0, 120, 240], [0, 30, 0]);

  return (
    <AbsoluteFill
      style={{
        background: "linear-gradient(160deg, #2b1055 0%, #4b1d8f 45%, #7b2ff7 100%)",
      }}
    >
      <AbsoluteFill
        style={{
          background: `radial-gradient(circle at ${30 + shift}% 20%, rgba(255,90,205,0.45), transparent 45%),
                       radial-gradient(circle at ${75 - shift}% 80%, rgba(64,180,255,0.40), transparent 45%)`,
        }}
      />
    </AbsoluteFill>
  );
};
