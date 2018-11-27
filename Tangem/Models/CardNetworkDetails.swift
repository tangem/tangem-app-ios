//
//  CardNetworkDetails.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation

struct CardNetworkArtwork: Codable {

    var date: String
    var hash: String
    var artworkId: String

    enum CodingKeys: String, CodingKey {
        case date
        case hash
        case artworkId = "id"
    }

}

struct CardNetworkDetails: Codable {

    var cardId: String
    var artwork: CardNetworkArtwork
    var batch: String
    var isValid: Bool

    enum CodingKeys: String, CodingKey {
        case cardId = "CID"
        case artwork
        case batch
        case isValid = "passed"
    }
    
}
