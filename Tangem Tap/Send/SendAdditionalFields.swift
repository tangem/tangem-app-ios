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
    
    static func fields(for cardInfo: CardInfo) -> SendAdditionalFields {
        guard let blockchain = cardInfo.defaultBlockchain else { return .none }
        
        switch blockchain {
        case .stellar, .binance:
            return .memo
        case .xrp:
            return .destinationTag
        default:
            return .none
        }
    }
}
