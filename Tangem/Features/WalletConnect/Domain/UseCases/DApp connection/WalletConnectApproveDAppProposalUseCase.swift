//
//  WalletConnectApproveDAppProposalUseCase.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import enum BlockchainSdk.Blockchain

final class WalletConnectApproveDAppProposalUseCase {
    private let dAppProposalApprovalService: any WalletConnectDAppProposalApprovalService

    init(dAppProposalApprovalService: some WalletConnectDAppProposalApprovalService) {
        self.dAppProposalApprovalService = dAppProposalApprovalService
    }

    /// - Note: Methods of the non-isolated `WalletConnectApproveDAppProposalUseCase` are implicitly `nonisolated`,
    /// and Swift 5 mode runs such `async` ones as Swift 6.2 `@concurrent`;
    /// `nonisolated(nonsending)` keeps the non-Sendable `wcAccountsWalletModelProvider` and `selectedAccount` on the caller's actor.
    nonisolated(nonsending) func callAsFunction(
        sessionProposal: WalletConnectDAppSessionProposal,
        selectedBlockchains: [Blockchain],
        wcAccountsWalletModelProvider: some WalletConnectAccountsWalletModelProvider,
        selectedAccount: some CryptoAccountModel
    ) async throws(WalletConnectDAppProposalApprovalError) -> WalletConnectDAppSession {
        let request = try sessionProposal.dAppAccountConnectionRequestFactory(
            selectedBlockchains,
            selectedAccount,
            wcAccountsWalletModelProvider
        )
        return try await dAppProposalApprovalService.approveConnectionProposal(with: request)
    }
}
