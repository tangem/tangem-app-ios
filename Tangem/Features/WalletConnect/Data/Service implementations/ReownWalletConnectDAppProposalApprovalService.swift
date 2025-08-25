//
//  ReownWalletConnectDAppProposalApprovalService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import protocol Foundation.LocalizedError
import ReownWalletKit

final class ReownWalletConnectDAppProposalApprovalService: WalletConnectDAppProposalApprovalService {
    private let walletConnectService: any WCService

    init(walletConnectService: some WCService) {
        self.walletConnectService = walletConnectService
    }

    func approveConnectionProposal(
        with request: WalletConnectDAppConnectionRequest
    ) async throws(WalletConnectDAppProposalApprovalError) -> WalletConnectDAppSession {
        let reownNamespaces = WalletConnectSessionNamespaceMapper.mapFromDomain(request.namespaces)

        do {
            let reownSession = try await walletConnectService.approveSessionProposal(with: request.proposalID, namespaces: reownNamespaces)
            return WalletConnectDAppSessionMapper.mapToDomain(reownSession, domainNamespaces: request.namespaces)
        } catch {
            try Self.parseConnectionProposalHasExpiredError(error)
            throw WalletConnectDAppProposalApprovalError.approvalFailed(error)
        }
    }

    func rejectConnectionProposal(
        with proposalID: String,
        reason: WalletConnectDAppSessionProposalRejectionReason
    ) async throws(WalletConnectDAppProposalApprovalError) {
        let reownReason = WalletConnectDAppSessionProposalMapper.mapRejectionReason(fromDomain: reason)

        do {
            try await walletConnectService.rejectSessionProposal(with: proposalID, reason: reownReason)
        } catch {
            throw WalletConnectDAppProposalApprovalError.rejectionFailed(error)
        }
    }

    private static func parseConnectionProposalHasExpiredError(_ approvingError: some Error) throws(WalletConnectDAppProposalApprovalError) {
        guard let localizedApprovingError = approvingError as? LocalizedError else { return }

        // [REDACTED_USERNAME], internal error types that are hidden inside ReownWalletKit library code...
        // no other options to check this exact error, except for runtime reflection, which is just as ugly and fragile,
        // but slower... 🚾

        // [REDACTED_TODO_COMMENT]
        // that current version of ReownWalletKit has this exact errorDescription

        if localizedApprovingError.errorDescription?.starts(with: "Proposal expired") == true {
            throw WalletConnectDAppProposalApprovalError.proposalExpired
        }
    }
}
