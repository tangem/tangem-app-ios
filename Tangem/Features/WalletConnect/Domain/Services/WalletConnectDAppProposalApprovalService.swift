//
//  WalletConnectDAppProposalApprovalService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol WalletConnectDAppProposalApprovalService {
    func approveConnectionProposal(
        with request: WalletConnectDAppConnectionRequest
    ) async throws(WalletConnectDAppProposalApprovalError) -> WalletConnectDAppSession

    func rejectConnectionProposal(
        with proposalID: String,
        reason: WalletConnectDAppSessionProposalRejectionReason
    ) async throws(WalletConnectDAppProposalApprovalError)
}
