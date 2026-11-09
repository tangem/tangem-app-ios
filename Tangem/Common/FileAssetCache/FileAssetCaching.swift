//
//  FileAssetCaching.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Returns a local file URL for a remote asset, downloading and caching it once.
protocol FileAssetCaching: Sendable {
    func localURL(remoteURL url: URL, checksum: String) async throws -> URL

    func retainingOnly(_ keys: Set<FileAssetCacheKey>) async
}
