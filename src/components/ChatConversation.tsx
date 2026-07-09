import { useCurrentFrame, useVideoConfig, spring, interpolate, AbsoluteFill } from "remotion";
import type { Conversation } from "../types";
import { PER_MESSAGE_SECONDS } from "../config";

const Bubble: React.FC<{ mine: boolean; text: string; delayFrames: number }> = ({
  mine,
  text,
  delayFrames,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const local = frame - delayFrames;

  const appear = spring({ frame: local, fps, config: { damping: 14, mass: 0.5 } });
  const opacity = interpolate(local, [0, 6], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const translateY = interpolate(appear, [0, 1], [40, 0]);

  return (
    <div
      style={{
        display: "flex",
        justifyContent: mine ? "flex-end" : "flex-start",
        opacity,
        transform: `translateY(${translateY}px)`,
        marginBottom: 26,
      }}
    >
      <div
        style={{
          maxWidth: "78%",
          padding: "26px 34px",
          borderRadius: 40,
          borderBottomRightRadius: mine ? 8 : 40,
          borderBottomLeftRadius: mine ? 40 : 8,
          background: mine ? "linear-gradient(135deg,#2f9bff,#1e6bff)" : "#eceef2",
          color: mine ? "#fff" : "#12141a",
          fontSize: 46,
          fontWeight: 600,
          lineHeight: 1.3,
          boxShadow: "0 10px 30px rgba(0,0,0,0.25)",
        }}
      >
        {text}
      </div>
    </div>
  );
};

// Affiche une conversation : etiquette + bulles qui apparaissent une par une.
export const ChatConversation: React.FC<{ conversation: Conversation }> = ({ conversation }) => {
  const { fps } = useVideoConfig();
  const step = Math.round(PER_MESSAGE_SECONDS * fps);

  return (
    <AbsoluteFill style={{ justifyContent: "flex-end", padding: "0 70px 150px 70px" }}>
      <div
        style={{
          alignSelf: "center",
          marginBottom: 40,
          padding: "12px 30px",
          borderRadius: 30,
          background: "rgba(0,0,0,0.35)",
          color: "#fff",
          fontSize: 40,
          fontWeight: 700,
        }}
      >
        💬 {conversation.personLabel}
      </div>
      {conversation.messages.map((m, i) => (
        <Bubble key={i} mine={m.from === "me"} text={m.text} delayFrames={i * step} />
      ))}
    </AbsoluteFill>
  );
};
