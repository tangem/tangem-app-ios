//
//  StoryAssetReconcileService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemStories

/// Removes cache files for story assets no longer referenced by the full manifest of every story.
final class StoryAssetReconcileService {
    @Injected(\.storiesV2RemoteStore) private var remoteStore: StoriesV2RemoteStore
    @Injected(\.storiesV2AssetCache) private var cache: StoryAssetCaching

    func reconcile() async {
        do {
            let slugs = StoriesV2StoryID.allCases.map(\.rawValue)
            let stories = try await remoteStore.stories(slugs: slugs)

            let keys = Set(stories.flatMap(\.assetCacheKeys))
            await cache.retainingOnly(keys)
        } catch {
            AppLogger.error("Story asset reconcile skipped", error: error)
        }
    }
}
