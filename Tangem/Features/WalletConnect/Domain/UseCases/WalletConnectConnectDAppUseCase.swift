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
        selectedBlockchains: Set<Blockchain>,
        selectedUserWallet: some UserWalletModel
    ) async throws {
        let request = try proposal.dAppConnectionRequestFactory(selectedBlockchains, selectedUserWallet)
        try await dAppConnectionService.connectDApp(with: request)
        // [REDACTED_TODO_COMMENT]
    }
}
