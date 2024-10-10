//
//  AnyWalletManagerFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdkLocal

protocol AnyWalletManagerFactory {
    func makeWalletManager(for token: StorageEntry, keys: [CardDTO.Wallet], apiList: APIList) throws -> WalletManager
}

enum AnyWalletManagerFactoryError: Error {
    case entryHasNotDerivationPath
    case noDerivation
    case walletWithBlockchainCurveNotFound
}
