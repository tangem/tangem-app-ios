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

    func callAsFunction(
        sessionProposal: WalletConnectDAppSessionProposal,
        selectedBlockchains: [Blockchain],
        selectedUserWallet: some UserWalletModel
    ) async throws(WalletConnectDAppProposalApprovalError) -> WalletConnectDAppSession {
        let request = try sessionProposal.dAppWalletConnectionRequestFactory(selectedBlockchains, selectedUserWallet)
        return try await dAppProposalApprovalService.approveConnectionProposal(with: request)
    }

    func callAsFunction(
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
