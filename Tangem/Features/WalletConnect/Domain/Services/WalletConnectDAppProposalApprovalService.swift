//
//  WalletConnectDAppProposalApprovalService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol WalletConnectDAppProposalApprovalService {
    // [REDACTED_TODO_COMMENT]
    func approveConnectionProposal(
        with request: WalletConnectDAppConnectionRequest,
        _ userWalletID: String
    ) async throws(WalletConnectDAppProposalApprovalError)

    func rejectConnectionProposal(
        with proposalID: String,
        reason: WalletConnectDAppSessionProposalRejectionReason
    ) async throws(WalletConnectDAppProposalApprovalError)
}
