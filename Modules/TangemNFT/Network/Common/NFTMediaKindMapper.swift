//
//  NFTMediaKindMapper.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import UniformTypeIdentifiers

/// - Note: Shared between `Moralis`, `NFTScan` and other providers.
struct NFTMediaKindMapper {
    func map(mimetype: String?) -> NFTAsset.Media.Kind {
        let mimeType = mimetype.flatMap(UTType.init)

        switch mimeType {
        case .png,
             .jpeg,
             .heic,
             .webP,
             .tiff,
             .bmp,
             .svg,
             .image:
            return .image
        case .gif:
            return .animation
        case .quickTimeMovie,
             .mpeg,
             .mpeg2Video,
             .mpeg4Movie,
             .avi,
             .video,
             .movie:
            return .video
        case .mp3,
             .wav,
             .aiff,
             .audio:
            return .audio
        default:
            return .unknown
        }
    }
}
