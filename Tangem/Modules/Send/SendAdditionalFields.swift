//
//  SendAdditionalFields.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

enum SendAdditionalFields {
    case memo
    case destinationTag
    case none

    static func fields(for blockchain: Blockchain) -> SendAdditionalFields {
        switch blockchain {
        case .stellar, .binance, .ton:
            return .memo
        case .xrp:
            return .destinationTag
        default:
            return .none
        }
    }
}
