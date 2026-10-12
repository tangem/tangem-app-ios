//
//  VisaWalletFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct VisaWalletFactory: AnyWalletFactory {
    func makeWallet(blockchainNetwork: BlockchainNetwork, keys: [KeyInfo]) throws -> Wallet {
        try SimpleWalletFactory().makeWallet(blockchainNetwork: blockchainNetwork, keys: keys)
    }
}
