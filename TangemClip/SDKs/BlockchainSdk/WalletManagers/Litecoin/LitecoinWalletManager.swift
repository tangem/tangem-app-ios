//
//  LitecoinWalletManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class LitecoinWalletManager: BitcoinWalletManager {
    override var relayFee: Decimal? {
        return Decimal(0.00001)
    }
}
