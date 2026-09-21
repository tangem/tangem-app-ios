//
//  StoriesV2PrefetchService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemStories

/// Downloads story assets ahead of time, so a story opens from local files.
final class StoriesV2PrefetchService {
    @Injected(\.storiesV2RemoteStore) private var remoteStore: StoriesV2RemoteStore
    @Injected(\.storiesV2AssetPrefetchService) private var assetPrefetchService: StoryAssetPrefetchService

    private var startupTask: Task<Void, Never>?

    /// Detached so the app start is never blocked; cancellation reaches the downloads.
    func prefetchOnAppStart() {
        guard FeatureProvider.isAvailable(.storiesV2) else { return }

        startupTask?.cancel()
        startupTask = runTask(in: self, isDetached: true, priority: .medium) { strongSelf in
            await strongSelf.prefetch(StoriesV2StoryID.prefetchedOnAppStart)
        }
    }

    /// The returned stories carry local asset URLs, ready for the player.
    @discardableResult
    func prefetch(_ ids: [StoriesV2StoryID]) async -> [StoryV2] {
        do {
            let stories = try await remoteStore.stories(slugs: ids.map(\.rawValue))
            return await prefetchAssets(of: stories)
        } catch is CancellationError {
            return []
        } catch {
            AppLogger.error("Stories V2 prefetch failed", error: error)
            return []
        }
    }

    /// A story carries several megabytes of video, so only a few download at a time — a large
    /// batch must not take over the cooperative pool. The show order is preserved.
    private func prefetchAssets(of stories: [StoryV2]) async -> [StoryV2] {
        await withTaskGroup(of: (offset: Int, story: StoryV2?).self) { group in
            var remaining = stories.enumerated().makeIterator()
            var prefetched = [StoryV2?](repeating: nil, count: stories.count)

            func addNextTask() {
                guard let (offset, story) = remaining.next() else { return }

                // A superseded pass stops feeding the group instead of spawning doomed children.
                _ = group.addTaskUnlessCancelled { [assetPrefetchService] in
                    // A cancelled or failed story leaves the batch without taking the rest with it.
                    (offset, try? await assetPrefetchService.prefetch(story))
                }
            }

            for _ in 0 ..< Constants.maxConcurrentStories {
                addNextTask()
            }

            while let (offset, story) = await group.next() {
                prefetched[offset] = story
                addNextTask()
            }

            return prefetched.compactMap(\.self)
        }
    }
}

// MARK: - Constants

private extension StoriesV2PrefetchService {
    enum Constants {
        static let maxConcurrentStories = 3
    }
}
