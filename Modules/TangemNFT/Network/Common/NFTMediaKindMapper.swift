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
enum NFTMediaKindMapper {
    // MARK: Private

    private static let imageTypes: Set<UTType> = .init(
        [.png, .jpeg, .heic, .webP, .tiff, .bmp, .svg, .image]
    )

    private static let gifTypes: Set<UTType> = .init(
        [.gif]
    )

    private static let videoTypes: Set<UTType> = .init(
        [.quickTimeMovie, .mpeg, .mpeg2Video, .mpeg4Movie, .avi, .video, .movie]
    )

    private static let audioTypes: Set<UTType> = .init(
        [.mp3, .wav, .aiff, .audio]
    )

    private static let mimeTypeGroups: [(types: Set<UTType>, mediaKind: NFTMedia.Kind)] = [
        (imageTypes, .image),
        (gifTypes, .animation),
        (videoTypes, .video),
        (audioTypes, .audio),
    ]

    // MARK: Implementation

    static func map(mimetype: String?) -> NFTMedia.Kind {
        guard let mimeType = mimetype.flatMap(UTType.init) else {
            return .unknown
        }

        return mimeTypeGroups.first { types, _ in
            types.contains(mimeType)
        }?.mediaKind ?? .unknown
    }

    static func map(_ url: URL) -> NFTMedia.Kind {
        mimeTypeGroups.first { types, _ in
            types.map(\.preferredFilenameExtension).contains(url.pathExtension)
        }?.mediaKind ?? .unknown
    }
}
