//
//  WalletConnectGetDAppConnectionProposalUseCase.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

final class WalletConnectGetDAppConnectionProposalUseCase {
    private let dAppDataService: any WalletConnectDAppDataService
    private let dAppProposalApprovalService: any WalletConnectDAppProposalApprovalService
    private let verificationService: any WalletConnectDAppVerificationService

    private let uri: WalletConnectRequestURI

    init(
        dAppDataService: some WalletConnectDAppDataService,
        dAppProposalApprovalService: some WalletConnectDAppProposalApprovalService,
        verificationService: some WalletConnectDAppVerificationService,
        uri: WalletConnectRequestURI
    ) {
        self.dAppDataService = dAppDataService
        self.dAppProposalApprovalService = dAppProposalApprovalService
        self.verificationService = verificationService
        self.uri = uri
    }

    func callAsFunction() async throws(WalletConnectDAppProposalLoadingError) -> WalletConnectDAppConnectionProposal {
        let (dAppData, sessionProposal) = try await getDAppDataAndProposal()

        guard !Task.isCancelled else {
            throw WalletConnectDAppProposalLoadingError.cancelledByUser
        }

        let verificationStatus = await getVerificationStatus(from: dAppData, proposal: sessionProposal)

        return WalletConnectDAppConnectionProposal(
            dAppData: dAppData,
            verificationStatus: verificationStatus,
            sessionProposal: sessionProposal
        )
    }

    private func getDAppDataAndProposal() async
        throws(WalletConnectDAppProposalLoadingError)
        -> (WalletConnectDAppData, WalletConnectDAppSessionProposal) {
        do {
            return try await dAppDataService.getDAppDataAndProposal(for: uri)

        } catch WalletConnectDAppProposalLoadingError.unsupportedDomain(let unsupportedDomainError) {
            try? await dAppProposalApprovalService.rejectConnectionProposal(
                with: unsupportedDomainError.proposalID,
                reason: .unsupportedDAppDomain
            )
            throw WalletConnectDAppProposalLoadingError.unsupportedDomain(unsupportedDomainError)

        } catch WalletConnectDAppProposalLoadingError.unsupportedBlockchains(let unsupportedBlockchainsError) {
            try? await dAppProposalApprovalService.rejectConnectionProposal(
                with: unsupportedBlockchainsError.proposalID,
                reason: .unsupportedBlockchains
            )
            throw WalletConnectDAppProposalLoadingError.unsupportedBlockchains(unsupportedBlockchainsError)

        } catch WalletConnectDAppProposalLoadingError.noBlockchainsProvidedByDApp(let noBlockchainsProvidedByDAppError) {
            try? await dAppProposalApprovalService.rejectConnectionProposal(
                with: noBlockchainsProvidedByDAppError.proposalID,
                reason: .unsupportedBlockchains
            )
            throw WalletConnectDAppProposalLoadingError.noBlockchainsProvidedByDApp(noBlockchainsProvidedByDAppError)

        } catch {
            throw error
        }
    }

    private func getVerificationStatus(
        from dAppData: WalletConnectDAppData,
        proposal: WalletConnectDAppSessionProposal
    ) async -> WalletConnectDAppVerificationStatus {
        switch proposal.initialVerificationContext?.validationStatus {
        case .valid, nil:
            break

        case .invalid:
            return .malicious
        }

        do {
            return try await verificationService.verify(dAppDomain: dAppData.domain)
        } catch {
            return .unknownDomain
        }
    }
}
