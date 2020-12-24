//
//  SendAdditionalFields.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

enum SendAdditionalFields {
    case memo, destinationTag, none
    
    static func fields(for card: Card) -> SendAdditionalFields {
        guard
            let blockchainName = card.cardData?.blockchainName,
            let curve = card.curve,
            let blockchain = Blockchain.from(blockchainName: blockchainName, curve: curve)
        else { return .none }
        
        switch blockchain {
        case .stellar:
            return .memo
        case .xrp:
            return .destinationTag
        default:
            return .none
        }
    }
}
