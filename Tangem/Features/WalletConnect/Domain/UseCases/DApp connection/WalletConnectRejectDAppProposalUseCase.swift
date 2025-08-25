//
//  WalletConnectRejectDAppProposalUseCase.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

final class WalletConnectRejectDAppProposalUseCase {
    private let dAppProposalApprovalService: any WalletConnectDAppProposalApprovalService

    init(dAppProposalApprovalService: some WalletConnectDAppProposalApprovalService) {
        self.dAppProposalApprovalService = dAppProposalApprovalService
    }

    func callAsFunction(proposalID: String) async throws(WalletConnectDAppProposalApprovalError) {
        try await dAppProposalApprovalService.rejectConnectionProposal(with: proposalID, reason: .userInitiated)
    }
}
