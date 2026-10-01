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

    func prefetchStory(_ id: StoriesV2StoryID) async throws -> StoryV2? {
        let prefetched = try await prefetchedStories(for: [id])

        try Task.checkCancellation()

        return try prefetched.first?.get()
    }

    /// The returned stories carry local asset URLs, ready for the player.
    @discardableResult
    func prefetch(_ ids: [StoriesV2StoryID]) async -> [StoryV2] {
        do {
            let prefetched = try await prefetchedStories(for: ids)

            try Task.checkCancellation()

            return prefetched.compactMap { try? $0.get() }
        } catch is CancellationError {
            return []
        } catch {
            AppLogger.error("Stories V2 prefetch failed", error: error)
            return []
        }
    }

    private func prefetchedStories(for ids: [StoriesV2StoryID]) async throws -> [Result<StoryV2, Error>] {
        let stories = try await remoteStore.stories(slugs: ids.map(\.rawValue))

        return await prefetchAssets(of: stories)
    }

    /// A story carries several megabytes of video, so only a few download at a time — a large
    /// batch must not take over the cooperative pool. The show order is preserved.
    private func prefetchAssets(of stories: [StoryV2]) async -> [Result<StoryV2, Error>] {
        await withTaskGroup(of: (offset: Int, result: Result<StoryV2, Error>).self) { group in
            var remaining = stories.enumerated().makeIterator()
            var prefetched = [Result<StoryV2, Error>?](repeating: nil, count: stories.count)

            func addNextTask() {
                guard let (offset, story) = remaining.next() else { return }

                // A superseded pass stops feeding the group instead of spawning doomed children.
                let added = group.addTaskUnlessCancelled { [assetPrefetchService] in
                    do {
                        return (offset, .success(try await assetPrefetchService.prefetch(story)))
                    } catch {
                        return (offset, .failure(error))
                    }
                }

                if !added {
                    prefetched[offset] = .failure(CancellationError())
                }
            }

            for _ in 0 ..< Constants.maxConcurrentStories {
                addNextTask()
            }

            while let (offset, result) = await group.next() {
                prefetched[offset] = result
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
