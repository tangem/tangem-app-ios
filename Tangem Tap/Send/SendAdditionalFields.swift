//
//  SendAdditionalFields.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

enum SendAdditionalFields {
    case memo, destinationTag, none
    
    static func fields(for card: Card) -> SendAdditionalFields {
        switch card.cardData?.blockchainName?.lowercased() {
        case "xlm":
            return .memo
        case "xrp":
            return .destinationTag
        default:
            return .none
        }
    }
}
