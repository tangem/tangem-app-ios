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
    func makeWalletManager(wallet: Wallet, tokens: [Token], apiList: APIList) throws -> WalletManager
}
