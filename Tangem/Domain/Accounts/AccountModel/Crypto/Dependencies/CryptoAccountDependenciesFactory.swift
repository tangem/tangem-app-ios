//
//  CryptoAccountDependenciesFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// Produces required dependencies for a specific account identified by its derivation index.
protocol CryptoAccountDependenciesFactory {
    func makeDependencies(
        forAccountWithDerivationIndex derivationIndex: Int,
        userWalletModelProvider: LazyUserWalletModelProvider
    ) -> CryptoAccountDependencies
}
