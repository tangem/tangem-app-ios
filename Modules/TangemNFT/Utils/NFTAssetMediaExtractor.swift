//
//  NFTAssetMediaExtractor.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

// [REDACTED_TODO_COMMENT]
@available(iOS, deprecated: 100000.0, message: "Temporary solution until full support for custom media content is implemented ([REDACTED_INFO])")
enum NFTAssetMediaExtractor {
    static func extractMedia(from asset: NFTAsset) -> NFTMedia? {
        let imageOrAnimation = asset
            .mediaFiles
            .first { $0.kind == .image || $0.kind == .animation }

        return imageOrAnimation ?? asset.mediaFiles.first
    }
}
