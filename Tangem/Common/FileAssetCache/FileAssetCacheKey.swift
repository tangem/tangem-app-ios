//
//  FileAssetCacheKey.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct FileAssetCacheKey: Hashable, Sendable {
    let url: URL
    let checksum: String
}
