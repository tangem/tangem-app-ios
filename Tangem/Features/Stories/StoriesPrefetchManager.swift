//
//  StoriesPrefetchManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation
import TangemStories

final class StoriesPrefetchManager: @unchecked Sendable {
    @Injected(\.storiesV2PrefetchService)
    private var storiesV2PrefetchService: StoriesV2PrefetchService

    private let legacyStoriesPrefetchService = StoryDataPrefetchService()
    private let hardwareUpgradeStoriesResolver = HardwareUpgradeStoriesResolver()

    private let prefetchTasks = OSAllocatedUnfairLock<[Step: Task<Void, Never>]>(initialState: [:])

    func prefetch(for step: Step) {
        step.legacyStories.forEach(legacyStoriesPrefetchService.prefetchStoryIfNeeded)
        prefetchStoriesV2(for: step)
    }

    func storiesToPrefetch(for step: Step) -> [StoriesV2StoryID] {
        step.storiesV2.filter(shouldPrefetch)
    }
}

// MARK: - Step

extension StoriesPrefetchManager {
    enum Step: Hashable {
        case appStart
    }
}

extension StoriesPrefetchManager.Step {
    var legacyStories: [TangemStory] {
        switch self {
        case .appStart: [.swap(.initialWithoutImages), .yieldFirstActivationAPYBoostStory]
        }
    }

    var storiesV2: [StoriesV2StoryID] {
        switch self {
        case .appStart: StoriesV2StoryID.prefetchedOnAppStart
        }
    }
}

// MARK: - Private implementation

private extension StoriesPrefetchManager {
    func prefetchStoriesV2(for step: Step) {
        let task = runTask(in: self, isDetached: true, priority: .medium) { manager in
            let stories = manager.storiesToPrefetch(for: step)
            guard !stories.isEmpty else { return }

            await manager.storiesV2PrefetchService.prefetch(stories)
        }

        prefetchTasks.withLock { tasks in
            tasks[step]?.cancel()
            tasks[step] = task
        }
    }

    func shouldPrefetch(_ story: StoriesV2StoryID) -> Bool {
        switch story {
        case .hardwareUpgrade: hardwareUpgradeStoriesResolver.shouldPrefetchStories()
        case .firstTimeSwap, .firstTimeYieldPromo, .swapFirstTry: true
        }
    }
}
