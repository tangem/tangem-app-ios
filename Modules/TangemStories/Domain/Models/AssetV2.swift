//
//  AssetV2.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct AssetV2: Equatable {
    public let type: AssetType
    public let contentMode: StoryContentMode
    public let durationMs: Int
    public let url: URL?
    public let checksum: String
    public let posterURL: URL?
    public let posterChecksum: String

    public init(
        type: AssetType,
        contentMode: StoryContentMode = .cover,
        durationMs: Int,
        url: URL?,
        checksum: String = "",
        posterURL: URL? = nil,
        posterChecksum: String = ""
    ) {
        self.type = type
        self.contentMode = contentMode
        self.durationMs = durationMs
        self.url = url
        self.checksum = checksum
        self.posterURL = posterURL
        self.posterChecksum = posterChecksum
    }

    public func resolvingLocal(url localURL: URL?, poster localPosterURL: URL?) -> AssetV2 {
        AssetV2(
            type: type, contentMode: contentMode, durationMs: durationMs,
            url: localURL ?? url, checksum: checksum,
            posterURL: localPosterURL ?? posterURL, posterChecksum: posterChecksum
        )
    }
}

public enum AssetType: String, Equatable {
    case video
    case lottie
    case image
}

public enum StoryContentMode: String, Equatable {
    case cover
    case contain
}
