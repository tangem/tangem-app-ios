//
//  CryptoAccountDependencies.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct CryptoAccountDependencies: BalanceProvidingAccountDependencies {
    let userTokensManager: UserTokensManager
    let walletModelsManager: WalletModelsManager
    let walletModelsFactoryInput: WalletModelsFactoryInput
    let derivationManager: (DerivationManager & DerivationStatusProvider)?
}
