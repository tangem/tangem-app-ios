//
//  SlidePlayerViewModel+Engine.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension SlidePlayerViewModel {
    /// Everything about a slide's playback that the published `state` can't express: the latches
    /// that outlive a transition, the playhead, and which haptic clusters have already fired.
    @MainActor
    final class Engine {
        /// Idle and prepared slides both render as `.preparing`, but only an unprepared one may
        /// open the asset — a second prepare would leak an AVPlayer.
        var hasPrepared = false
        var isPaused = false
        var isSeekingToStart = false
        var didReachEndWhilePaused = false

        /// Drives progress only; for video the real media length takes over. Analytics must keep
        /// reporting the contract value from `slide.asset.durationMs`.
        var playbackDurationMs: Double = 0

        private(set) var watchedMs = 0
        private(set) var elapsedMs: Double = 0

        private var hapticClusters: [HapticCluster] = []
        private var firedHapticClusters = Set<Int>()

        var hasHaptics: Bool { !hapticClusters.isEmpty }
        var didReachDuration: Bool { elapsedMs >= playbackDurationMs }
        var progressValue: Double { min(elapsedMs / max(playbackDurationMs, 1), 1) }

        func loadHapticClusters(from marks: [Int]) {
            hapticClusters = StoryHapticClusterizer.clusters(from: marks)
        }

        func reset() {
            elapsedMs = 0
            watchedMs = 0
            didReachEndWhilePaused = false
            firedHapticClusters.removeAll()
        }

        /// Ticker path: the playhead is ours to advance.
        func advance(by delta: TimeInterval) {
            elapsedMs += delta * 1000
            watchedMs = Int(elapsedMs)
        }

        /// Video path: the playhead belongs to `AVPlayer` and can report backwards across a seek,
        /// so the watched total only ever grows.
        func moveHead(toMs ms: Double) {
            elapsedMs = ms
            watchedMs = max(watchedMs, Int(ms))
        }

        /// Each cluster is handed out once, so the caller fires them without tracking what it played.
        func clustersToFire(atMs: Double) -> [HapticCluster] {
            hapticClusters.enumerated().compactMap { index, cluster in
                guard !firedHapticClusters.contains(index), atMs >= Double(cluster.startMs) else {
                    return nil
                }
                firedHapticClusters.insert(index)
                return cluster
            }
        }
    }
}
