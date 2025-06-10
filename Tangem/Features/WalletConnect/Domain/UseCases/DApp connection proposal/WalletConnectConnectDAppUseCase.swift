//
//  WalletConnectConnectDAppUseCase.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import enum BlockchainSdk.Blockchain

final class WalletConnectConnectDAppUseCase {
    private let dAppProposalApprovalService: any WalletConnectDAppProposalApprovalService

    init(dAppProposalApprovalService: some WalletConnectDAppProposalApprovalService) {
        self.dAppProposalApprovalService = dAppProposalApprovalService
    }

    func callAsFunction(
        proposal: WalletConnectSessionProposal,
        selectedBlockchains: some Sequence<Blockchain>,
        selectedUserWallet: some UserWalletModel
    ) async throws(WalletConnectDAppProposalApprovalError) {
        let request = try proposal.dAppConnectionRequestFactory(selectedBlockchains, selectedUserWallet)

        // [REDACTED_TODO_COMMENT]
        try await dAppProposalApprovalService.approveConnectionProposal(with: request, selectedUserWallet.userWalletId.stringValue)

        // [REDACTED_TODO_COMMENT]
    }
}
