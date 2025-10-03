//
//  AccountWalletModelsManagerFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// Produces `WalletModelsManager` instances for a specific account identified by its derivation index.
protocol AccountWalletModelsManagerFactory {
    func makeWalletModelsManager(forAccountWithDerivationIndex derivationIndex: Int) -> WalletModelsManager
}
