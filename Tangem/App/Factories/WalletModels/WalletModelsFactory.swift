//
//  WalletModelsFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol WalletModelsFactory {
    func makeWalletModels(for token: StorageEntry, keys: [CardDTO.Wallet]) throws -> [WalletModel]
}

enum WalletModelsFactoryError: Error {
    case entryHasNotDerivationPath
    case noDerivation
}
