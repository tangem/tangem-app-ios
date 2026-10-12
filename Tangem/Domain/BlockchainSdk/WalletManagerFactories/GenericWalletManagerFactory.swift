//
//  GenericWalletManagerFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct GenericWalletManagerFactory: AnyWalletManagerFactory {
    func makeWalletManager(wallet: Wallet, tokens: [Token], apiList: APIList) throws -> WalletManager {
        let factory = WalletManagerFactoryProvider(apiList: apiList).factory
        let walletManager = try factory.makeWalletManager(wallet: wallet)

        walletManager.addTokens(tokens)
        return walletManager
    }
}
