//
//  WalletStatus.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public enum WalletStatus: Int, Codable, StatusType {
    case empty = 1
    case loaded = 2
    case purged = 3

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode("\(self)".capitalized)
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.singleValueContainer()
        let stringValue = try values.decode(String.self).lowercasingFirst()
        switch stringValue {
        case "empty":
            self = .empty
        case "loaded":
            self = .loaded
        case "purged":
            self = .purged
        default:
            throw TangemSdkError.decodingFailed("Failed to decode WalletStatus")
        }
    }
    
    public init(from cardStatus: CardStatus) {
        switch cardStatus {
        case .empty, .notPersonalized:
            self = .empty
        case .loaded:
            self = .loaded
        case .purged:
            self = .purged
        }
    }
}
