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
    let connectDApp: WalletConnectConnectDAppUseCase
    let rejectDAppProposal: WalletConnectRejectDAppProposalUseCase
}
