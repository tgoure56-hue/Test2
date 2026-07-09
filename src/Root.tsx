import { Composition } from "remotion";
import { DailyVideo } from "./DailyVideo";
import { DEFAULT_DATA, type DailyData } from "./types";
import { FPS, WIDTH, HEIGHT, computeDurationInFrames } from "./config";

export const RemotionRoot: React.FC = () => {
  return (
    <Composition
      id="DailyVideo"
      component={DailyVideo}
      fps={FPS}
      width={WIDTH}
      height={HEIGHT}
      defaultProps={DEFAULT_DATA}
      // La duree s'adapte au nombre de messages du jour.
      calculateMetadata={({ props }) => {
        const data = props as DailyData;
        return { durationInFrames: computeDurationInFrames(data) };
      }}
    />
  );
};
