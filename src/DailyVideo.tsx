import { AbsoluteFill, Series } from "remotion";
import type { DailyData } from "./types";
import { FONT_FAMILY } from "./font";
import { useFontsReady } from "./font-loader";
import {
  FPS,
  INTRO_SECONDS,
  COUNTER_SECONDS,
  OUTRO_SECONDS,
  convoDurationInFrames,
} from "./config";
import { Background } from "./components/Background";
import { Intro } from "./components/Intro";
import { MoneyCounter } from "./components/MoneyCounter";
import { ChatConversation } from "./components/ChatConversation";
import { Outro } from "./components/Outro";

// Composition principale : enchaine intro -> compteur -> conversations -> outro.
export const DailyVideo: React.FC<DailyData> = (data) => {
  useFontsReady();
  return (
    <AbsoluteFill style={{ fontFamily: FONT_FAMILY }}>
      <Background />
      <Series>
        <Series.Sequence durationInFrames={Math.round(INTRO_SECONDS * FPS)}>
          <Intro day={data.day} />
        </Series.Sequence>

        <Series.Sequence durationInFrames={Math.round(COUNTER_SECONDS * FPS)}>
          <MoneyCounter
            total={data.totalRaised}
            goal={data.goal}
            currencySymbol={data.currencySymbol}
          />
        </Series.Sequence>

        {data.conversations.map((c, i) => (
          <Series.Sequence key={i} durationInFrames={convoDurationInFrames(c.messages.length)}>
            <ChatConversation conversation={c} />
          </Series.Sequence>
        ))}

        <Series.Sequence durationInFrames={Math.round(OUTRO_SECONDS * FPS)}>
          <Outro currencySymbol={data.currencySymbol} />
        </Series.Sequence>
      </Series>
    </AbsoluteFill>
  );
};
