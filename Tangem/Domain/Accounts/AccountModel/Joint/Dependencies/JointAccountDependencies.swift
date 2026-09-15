//
//  JointAccountDependencies.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// What a joint account is built out of: the same as one of the wallet's own, and the service its operations go through.
struct JointAccountDependencies: BalanceProvidingAccountDependencies {
    let userTokensManager: UserTokensManager
    let walletModelsManager: WalletModelsManager
    let walletModelsFactoryInput: WalletModelsFactoryInput
    let derivationManager: (DerivationManager & DerivationStatusProvider)?
    let operationsService: any JointAccountOperationsService
    let pendingOperationsProvider: any JointAccountPendingOperationsProvider
    let membersService: any JointAccountMembersService
}
