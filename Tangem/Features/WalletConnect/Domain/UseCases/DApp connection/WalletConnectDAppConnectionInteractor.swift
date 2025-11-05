//
//  WalletConnectDAppConnectionInteractor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct WalletConnectDAppConnectionInteractor {
    let getDAppConnectionProposal: WalletConnectGetDAppConnectionProposalUseCase
    let resolveAvailableBlockchains: WalletConnectResolveAvailableBlockchainsUseCase
    let approveDAppProposal: WalletConnectApproveDAppProposalUseCase
    let rejectDAppProposal: WalletConnectRejectDAppProposalUseCase
    let persistConnectedDApp: WalletConnectPersistConnectedDAppUseCase
    let migrateToAccounts: WalletConnectToAccountsMigrationUseCase
}
