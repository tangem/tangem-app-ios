//
//  NFTMedia.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct NFTMedia: Hashable, Sendable {
    enum Kind: Sendable {
        case image
        case animation
        case video
        case audio
        case unknown
    }

    let kind: Kind
    let url: URL
}
