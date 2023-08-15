//
//  AnyWalletManagerFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol AnyWalletManagerFactory {
    func makeWalletManager(
        tokens: [BlockchainSdk.Token],
        blockchainNetwork: BlockchainNetwork,
        keys: [CardDTO.Wallet]
    ) throws -> WalletManager
}

enum AnyWalletManagerFactoryError: Error {
    case entryHasNotDerivationPath
    case noDerivation
}
