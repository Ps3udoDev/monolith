import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/state/player_state.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import 'cover.dart';
import 'visualizer.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlayerState>();
    final track = state.currentTrack;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Material(
        color: AppTokens.surface2,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: state.openPlayer,
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 8, 10, 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTokens.hairline),
            ),
            child: Row(
              children: [
                Cover(tone: track.cover, seed: track.seed, size: 42, radius: 8, bars: 14),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.sans(size: 13.5, weight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 14,
                        child: Visualizer(
                          style: state.vizStyle,
                          seed: track.seed,
                          progress: state.progress,
                          height: 14,
                          interactive: false,
                          accent: AppTokens.accent(),
                          playing: state.playing,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: AppTokens.accent(),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: state.togglePlay,
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(
                        state.playing ? Icons.pause : Icons.play_arrow,
                        size: 20,
                        color: const Color(0xFF0A0A0C),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
