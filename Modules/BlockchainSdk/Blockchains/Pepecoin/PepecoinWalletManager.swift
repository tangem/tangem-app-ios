//
//  PepecoinWalletManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import TangemFoundation

class PepecoinWalletManager: DogecoinWalletManager {
    override var minimalFee: Decimal { 0.00001 }

    // MARK: - DustRestrictable

    /// https://github.com/pepecoinppc/pepecoin/blob/4fb5a0cd930c0df82c88292e973a7b7cfa06c4e8/doc/fee-recommendation.md
    override var dustValue: Amount {
        // Use soft dust value from documentation
        let dustValue = Decimal(stringValue: "0.01")!
        return Amount(with: wallet.blockchain, value: dustValue)
    }
}
