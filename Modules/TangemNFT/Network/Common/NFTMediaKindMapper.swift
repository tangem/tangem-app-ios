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

    // Sometimes mimetype is not available, although some media is
    // So let's at least try to convert unknows to some other kind (image, for instance, as the most common format)
    static func map(mimetype: String?, defaultKind: NFTMedia.Kind = .unknown) -> NFTMedia.Kind {
        guard let mimeType = mimetype.flatMap(UTType.init) else {
            return defaultKind
        }

        return mimeTypeGroups.first { types, _ in
            types.contains(mimeType)
        }?.mediaKind ?? defaultKind
    }

    static func map(_ url: URL, defaultKind: NFTMedia.Kind = .unknown) -> NFTMedia.Kind {
        mimeTypeGroups.first { types, _ in
            types.map(\.preferredFilenameExtension).contains(url.pathExtension)
        }?.mediaKind ?? defaultKind
    }
}
