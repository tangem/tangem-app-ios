//
//  AccountUserTokensManagerFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// Produces `UserTokensManager` instances for a specific account identified by its derivation index.
protocol AccountUserTokensManagerFactory {
    func makeUserTokensManager(
        forAccountWithDerivationIndex derivationIndex: Int,
        walletModelsManager: WalletModelsManager
    ) -> UserTokensManager
}
