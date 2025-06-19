//
//  ReownWalletConnectDAppDataService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import protocol Foundation.LocalizedError
import ReownWalletKit

final class ReownWalletConnectDAppDataService: WalletConnectDAppDataService {
    private let walletConnectService: any WCService

    init(walletConnectService: some WCService) {
        self.walletConnectService = walletConnectService
    }

    func getDAppDataAndProposal(
        for uri: WalletConnectRequestURI,
        source: Analytics.WalletConnectSessionSource
    ) async throws(WalletConnectDAppProposalLoadingError) -> (WalletConnectDAppData, WalletConnectDAppSessionProposal) {
        let reownSessionProposal = try await openSession(uri: uri, source: source)

        try Self.validateDomainIsSupported(from: reownSessionProposal)
        try Self.validateRequiredBlockchainsAreSupported(from: reownSessionProposal)

        let dAppData = WalletConnectDAppData(
            name: reownSessionProposal.proposer.name,
            domain: try WalletConnectDAppDataMapper.mapDomainURL(from: reownSessionProposal),
            icon: WalletConnectDAppDataMapper.mapIconURL(from: reownSessionProposal)
        )

        let requiredBlockchains = WalletConnectDAppSessionProposalMapper.mapRequiredBlockchains(from: reownSessionProposal)
        let optionalBlockchains = WalletConnectDAppSessionProposalMapper.mapOptionalBlockchains(from: reownSessionProposal)

        guard requiredBlockchains.isNotEmpty || optionalBlockchains.isNotEmpty else {
            throw WalletConnectDAppProposalLoadingError.noBlockchainsProvidedByDApp(
                .init(
                    proposalID: reownSessionProposal.id,
                    dAppName: reownSessionProposal.proposer.name
                )
            )
        }

        let sessionProposal = WalletConnectDAppSessionProposal(
            id: reownSessionProposal.id,
            requiredBlockchains: requiredBlockchains,
            optionalBlockchains: optionalBlockchains,
            dAppConnectionRequestFactory: { [reownSessionProposal] selectedBlockchains, selectedUserWallet
                throws(WalletConnectDAppProposalApprovalError) in

                let reownSessionNamespaces: [String: SessionNamespace]

                do {
                    reownSessionNamespaces = try AutoNamespaces.build(
                        sessionProposal: reownSessionProposal,
                        chains: selectedBlockchains.compactMap(WalletConnectBlockchainMapper.mapFromDomain),
                        methods: WalletConnectDAppSessionProposalMapper.mapAllMethods(from: reownSessionProposal),
                        events: WalletConnectDAppSessionProposalMapper.mapAllEvents(from: reownSessionProposal),
                        accounts: selectedBlockchains.flatMap { WalletConnectAccountsMapper.map(from: $0, userWalletModel: selectedUserWallet) }
                    )
                } catch {
                    throw WalletConnectDAppProposalApprovalError.invalidConnectionRequest(error)
                }

                return WalletConnectDAppConnectionRequest(
                    proposalID: reownSessionProposal.id,
                    namespaces: WalletConnectSessionNamespaceMapper.mapToDomain(reownSessionNamespaces)
                )
            }
        )

        return (dAppData, sessionProposal)
    }

    private func openSession(
        uri: WalletConnectRequestURI,
        source: Analytics.WalletConnectSessionSource
    ) async throws(WalletConnectDAppProposalLoadingError) -> Session.Proposal {
        do {
            return try await walletConnectService.openSession(with: uri, source: source)
        } catch is CancellationError {
            throw WalletConnectDAppProposalLoadingError.cancelledByUser
        } catch {
            try Self.parseURIAlreadyUsedError(error)
            throw WalletConnectDAppProposalLoadingError.pairingFailed(error)
        }
    }

    private static func parseURIAlreadyUsedError(_ pairingError: some Error) throws(WalletConnectDAppProposalLoadingError) {
        guard let localizedPairingError = pairingError as? LocalizedError else { return }

        // [REDACTED_USERNAME], internal error types that are hidden inside ReownWalletKit library code...
        // no other options to check this exact error, except for runtime reflection, which is just as ugly and fragile,
        // but slower... 🚾

        // [REDACTED_TODO_COMMENT]
        // that current version of ReownWalletKit has this exact errorDescription

        if localizedPairingError.errorDescription?.starts(with: "No pending requests for pairing") == true {
            throw WalletConnectDAppProposalLoadingError.uriAlreadyUsed
        }
    }
}

// MARK: - Validation

extension ReownWalletConnectDAppDataService {
    private static let unsupportedDAppDomains = [
        "dydx.exchange",
        "pro.apex.exchange",
        "sandbox.game",
        "app.paradex.trade",
    ]

    private static func validateRequiredBlockchainsAreSupported(
        from reownSessionProposal: Session.Proposal
    ) throws(WalletConnectDAppProposalLoadingError) {
        let unsupportedBlockchainNames = WalletConnectDAppSessionProposalMapper.mapUnsupportedRequiredBlockchainNames(from: reownSessionProposal)

        guard unsupportedBlockchainNames.isEmpty else {
            throw WalletConnectDAppProposalLoadingError.unsupportedBlockchains(
                .init(
                    proposalID: reownSessionProposal.id,
                    dAppName: reownSessionProposal.proposer.name,
                    blockchainNames: unsupportedBlockchainNames.sorted()
                )
            )
        }
    }

    private static func validateDomainIsSupported(
        from reownSessionProposal: Session.Proposal
    ) throws(WalletConnectDAppProposalLoadingError) {
        let dAppRawDomain = reownSessionProposal.proposer.url

        for unsupportedDAppDomain in Self.unsupportedDAppDomains {
            if dAppRawDomain.contains(unsupportedDAppDomain) {
                throw WalletConnectDAppProposalLoadingError.unsupportedDomain(
                    .init(
                        proposalID: reownSessionProposal.id,
                        dAppName: reownSessionProposal.proposer.name,
                        dAppRawDomain: dAppRawDomain
                    )
                )
            }
        }
    }
}
