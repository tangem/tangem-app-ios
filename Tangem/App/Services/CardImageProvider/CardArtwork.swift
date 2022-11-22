//
//  CardArtwork.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

enum CardArtwork: Equatable {
    case notLoaded
    case noArtwork
    case artwork(ArtworkInfo)

    var artworkInfo: ArtworkInfo? {
        switch self {
        case .artwork(let artwork):
            return artwork
        case .notLoaded, .noArtwork:
            return nil
        }
    }
}
