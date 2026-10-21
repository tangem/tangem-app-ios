//
//  RemoteCollectiblesOpeningMediaProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemStories

struct RemoteCollectiblesOpeningMediaProvider: CollectiblesOpeningMediaProvider {
    private let cache: any StoryAssetCaching

    init(cache: any StoryAssetCaching = Self.sharedCache) {
        self.cache = cache
    }

    func load(from url: URL) async throws -> URL {
        try await cache.localURL(remoteURL: url, checksum: .empty)
    }
}

// MARK: - Shared cache

private extension RemoteCollectiblesOpeningMediaProvider {
    static let sharedCache = CommonStoryAssetCache(directory: .collectiblesOpeningMedia)
}

// MARK: - Directory

private extension URL {
    static let collectiblesOpeningMedia: Self = cachesDirectory
        .appending(path: "CollectiblesOpeningMedia", directoryHint: .isDirectory)
}
