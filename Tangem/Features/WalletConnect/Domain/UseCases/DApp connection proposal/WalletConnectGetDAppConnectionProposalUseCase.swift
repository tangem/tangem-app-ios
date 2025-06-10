//
//  WalletConnectGetDAppConnectionProposalUseCase.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct Foundation.URL

final class WalletConnectGetDAppConnectionProposalUseCase {
    private let dAppDataService: any WalletConnectDAppDataService
    private let dAppProposalApprovalService: any WalletConnectDAppProposalApprovalService
    private let verificationService: any WalletConnectDAppVerificationService

    private let uri: WalletConnectRequestURI
    private let analyticsSource: Analytics.WalletConnectSessionSource

    init(
        dAppDataService: some WalletConnectDAppDataService,
        dAppProposalApprovalService: some WalletConnectDAppProposalApprovalService,
        verificationService: some WalletConnectDAppVerificationService,
        uri: WalletConnectRequestURI,
        analyticsSource: Analytics.WalletConnectSessionSource
    ) {
        self.dAppDataService = dAppDataService
        self.dAppProposalApprovalService = dAppProposalApprovalService
        self.verificationService = verificationService
        self.uri = uri
        self.analyticsSource = analyticsSource
    }

    func callAsFunction() async throws(WalletConnectDAppProposalLoadingError) -> WalletConnectDAppConnectionProposal {
        let (dAppData, sessionProposal) = try await getDAppDataAndProposal()

        guard !Task.isCancelled else {
            throw WalletConnectDAppProposalLoadingError.cancelledByUser
        }

        let verificationStatus: WalletConnectDAppVerificationStatus

        do {
            verificationStatus = try await verificationService.verify(dAppDomain: dAppData.domain)
        } catch {
            // [REDACTED_TODO_COMMENT]
            verificationStatus = .unknownDomain
        }

        return WalletConnectDAppConnectionProposal(dApp: dAppData, verificationStatus: verificationStatus, sessionProposal: sessionProposal)
    }

    private func getDAppDataAndProposal() async
        throws(WalletConnectDAppProposalLoadingError)
        -> (WalletConnectDAppData, WalletConnectSessionProposal) {
        do {
            return try await dAppDataService.getDAppDataAndProposal(for: uri, source: analyticsSource)

        } catch WalletConnectDAppProposalLoadingError.unsupportedBlockchains(let unsupportedBlockchainsError) {
            try? await dAppProposalApprovalService.rejectConnectionProposal(
                with: unsupportedBlockchainsError.proposalID,
                reason: .unsupportedBlockchains
            )
            throw WalletConnectDAppProposalLoadingError.unsupportedBlockchains(unsupportedBlockchainsError)

        } catch WalletConnectDAppProposalLoadingError.unsupportedDomain(let unsupportedDomainError) {
            try? await dAppProposalApprovalService.rejectConnectionProposal(
                with: unsupportedDomainError.proposalID,
                reason: .unsupportedDAppDomain
            )
            throw WalletConnectDAppProposalLoadingError.unsupportedDomain(unsupportedDomainError)

        } catch {
            throw error
        }
    }
}
