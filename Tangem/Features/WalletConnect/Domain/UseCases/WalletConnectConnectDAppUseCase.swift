//
//  WalletConnectConnectDAppUseCase.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import enum BlockchainSdk.Blockchain

final class WalletConnectConnectDAppUseCase {
    private let dAppConnectionService: any WalletConnectDAppConnectionService

    init(dAppConnectionService: some WalletConnectDAppConnectionService) {
        self.dAppConnectionService = dAppConnectionService
    }

    func callAsFunction(
        proposal: WalletConnectSessionProposal,
        selectedBlockchains: some Sequence<Blockchain>,
        selectedUserWallet: some UserWalletModel
    ) async throws {
        let request = try proposal.dAppConnectionRequestFactory(selectedBlockchains, selectedUserWallet)

        // [REDACTED_TODO_COMMENT]
        try await dAppConnectionService.connectDApp(with: request, selectedUserWallet.userWalletId.stringValue)

        // [REDACTED_TODO_COMMENT]
    }
}
