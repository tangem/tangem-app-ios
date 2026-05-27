//
//  XRPAmountConverter.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct XRPAmountConverter {
    private let blockchain: Blockchain

    init(curve: EllipticCurve) {
        blockchain = .xrp(curve: curve)
    }

    init(blockchain: Blockchain) {
        assert({
            if case .xrp = blockchain {
                return true
            }
            return false
        }())
        self.blockchain = blockchain
    }

    func convertToDrops(amount: Decimal) -> Decimal {
        amount * blockchain.decimalValue
    }

    func convertFromDrops(_ drops: Decimal) -> Decimal {
        drops / blockchain.decimalValue
    }
}
