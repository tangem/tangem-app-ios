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

    var isEmpty: Bool {
        switch self {
        case .memo, .destinationTag:
            return false
        case .none:
            return true
        }
    }

    static func fields(for blockchain: Blockchain) -> SendAdditionalFields {
        switch blockchain {
        case .stellar, .binance, .ton, .cosmos, .terraV1, .terraV2:
            return .memo
        case .xrp:
            return .destinationTag
        default:
            return .none
        }
    }
}
