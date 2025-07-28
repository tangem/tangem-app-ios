//
//  ReownWalletConnectDAppDataService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import protocol Foundation.LocalizedError
import ReownWalletKit
import enum BlockchainSdk.Blockchain

final class ReownWalletConnectDAppDataService: WalletConnectDAppDataService {
    private let walletConnectService: any WCService
    private let dAppIconURLResolver: WalletConnectDAppIconURLResolver

    init(
        walletConnectService: some WCService,
        dAppIconURLResolver: WalletConnectDAppIconURLResolver
    ) {
        self.walletConnectService = walletConnectService
        self.dAppIconURLResolver = dAppIconURLResolver
    }

    func getDAppDataAndProposal(
        for uri: WalletConnectRequestURI
    ) async throws(WalletConnectDAppProposalLoadingError) -> (WalletConnectDAppData, WalletConnectDAppSessionProposal) {
        let (reownSessionProposal, reownVerifyContext) = try await openSession(uri: uri)

        try Self.validateDomainIsSupported(from: reownSessionProposal)

        let requiredBlockchains = WalletConnectDAppSessionProposalMapper.mapRequiredBlockchains(from: reownSessionProposal)
        try Self.validateRequiredBlockchainsAreSupported(from: reownSessionProposal)

        let optionalBlockchains = WalletConnectDAppSessionProposalMapper.mapOptionalBlockchains(from: reownSessionProposal)
        try Self.validateOptionalBlockchainsAreSupported(
            from: reownSessionProposal,
            requiredBlockchains: requiredBlockchains,
            optionalBlockchains: optionalBlockchains
        )

        guard requiredBlockchains.isNotEmpty || optionalBlockchains.isNotEmpty else {
            throw WalletConnectDAppProposalLoadingError.noBlockchainsProvidedByDApp(
                .init(
                    proposalID: reownSessionProposal.id,
                    dAppName: reownSessionProposal.proposer.name
                )
            )
        }

        let specificSolanaCAIPReference = Self.parseSpecificSolanaCAIPReference(from: reownSessionProposal)

        let dAppDomain = try WalletConnectDAppSessionProposalMapper.mapDomainURL(from: reownSessionProposal)
        let dAppIconURL = await dAppIconURLResolver.resolveURL(from: reownSessionProposal.proposer.icons)

        let dAppData = WalletConnectDAppData(
            name: reownSessionProposal.proposer.name,
            domain: dAppDomain,
            icon: dAppIconURL
        )

        let sessionProposal = WalletConnectDAppSessionProposal(
            id: reownSessionProposal.id,
            requiredBlockchains: requiredBlockchains,
            optionalBlockchains: optionalBlockchains,
            initialVerificationContext: WalletConnectDAppSessionProposalMapper.mapVerificationContext(from: reownVerifyContext),
            dAppConnectionRequestFactory: { [reownSessionProposal] selectedBlockchains, selectedUserWallet
                throws(WalletConnectDAppProposalApprovalError) in

                func caipReference(for domainBlockchain: BlockchainSdk.Blockchain) -> String? {
                    domainBlockchain.networkId == Self.solanaDomainNetworkID
                        ? specificSolanaCAIPReference
                        : nil
                }

                let reownSessionNamespaces: [String: SessionNamespace]

                do {
                    reownSessionNamespaces = try AutoNamespaces.build(
                        sessionProposal: reownSessionProposal,
                        chains: selectedBlockchains.compactMap {
                            WalletConnectBlockchainMapper.mapFromDomain($0, preferredCAIPReference: caipReference(for: $0))
                        },
                        methods: WalletConnectDAppSessionProposalMapper.mapAllMethods(from: reownSessionProposal),
                        events: WalletConnectDAppSessionProposalMapper.mapAllEvents(from: reownSessionProposal),
                        accounts: selectedBlockchains.flatMap {
                            WalletConnectAccountsMapper.map(
                                from: $0,
                                userWalletModel: selectedUserWallet,
                                preferredCAIPReference: caipReference(for: $0)
                            )
                        }
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
        uri: WalletConnectRequestURI
    ) async throws(WalletConnectDAppProposalLoadingError) -> (Session.Proposal, VerifyContext?) {
        do {
            return try await walletConnectService.openSession(with: uri)
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

    /// Parses specific Solana blockchain CAIP-2 reference (if any).
    /// - Parameter reownSessionProposal: DApp session proposal that may have Solana blockchains.
    /// - Returns: Solana CAIP-2 reference if it was one and only one occurrence. For all other cases returns `nil`.
    private static func parseSpecificSolanaCAIPReference(from reownSessionProposal: ReownWalletKit.Session.Proposal) -> String? {
        let required = Self.extractSolanaBlockchains(from: reownSessionProposal.requiredNamespaces)
        let optional = Self.extractSolanaBlockchains(from: reownSessionProposal.optionalNamespaces)
        let solanaBlockchains = Set(required + optional)

        let hasSpecificSolanaCAIPReference = solanaBlockchains.count == 1

        guard hasSpecificSolanaCAIPReference else {
            return nil
        }

        return solanaBlockchains.first?.reference
    }

    private static func extractSolanaBlockchains(from reownNamespaces: [String: ReownWalletKit.ProposalNamespace]?) -> [ReownWalletKit.Blockchain] {
        guard let reownNamespaces else { return [] }

        return reownNamespaces.values
            .compactMap(\.chains)
            .flatMap { $0 }
            .filter { $0.namespace == Self.solanaCAIPNamespace }
    }
}

// MARK: - Validation

extension ReownWalletConnectDAppDataService {
    private static let solanaDomainNetworkID = BlockchainSdk.Blockchain.solana(curve: .ed25519, testnet: false).networkId
    private static let solanaCAIPNamespace = "solana"

    private static let unsupportedDAppHosts = [
        "dydx.trade",
        "pro.apex.exchange",
        "sandbox.game",
        "app.paradex.trade",
    ]

    private static func validateDomainIsSupported(
        from reownSessionProposal: Session.Proposal
    ) throws(WalletConnectDAppProposalLoadingError) {
        let dAppRawURL = reownSessionProposal.proposer.url

        for unsupportedDAppHost in Self.unsupportedDAppHosts {
            if dAppRawURL.contains(unsupportedDAppHost) {
                throw WalletConnectDAppProposalLoadingError.unsupportedDomain(
                    .init(
                        proposalID: reownSessionProposal.id,
                        dAppName: reownSessionProposal.proposer.name,
                        dAppRawURL: dAppRawURL
                    )
                )
            }
        }
    }

    private static func validateRequiredBlockchainsAreSupported(
        from reownSessionProposal: Session.Proposal
    ) throws(WalletConnectDAppProposalLoadingError) {
        let unsupportedRequiredBlockchainNames = WalletConnectDAppSessionProposalMapper.mapUnsupportedRequiredBlockchainNames(
            from: reownSessionProposal
        )

        guard unsupportedRequiredBlockchainNames.isEmpty else {
            throw WalletConnectDAppProposalLoadingError.unsupportedBlockchains(
                .init(
                    proposalID: reownSessionProposal.id,
                    dAppName: reownSessionProposal.proposer.name,
                    blockchainNames: unsupportedRequiredBlockchainNames.sorted()
                )
            )
        }
    }

    private static func validateOptionalBlockchainsAreSupported(
        from reownSessionProposal: Session.Proposal,
        requiredBlockchains: Set<BlockchainSdk.Blockchain>,
        optionalBlockchains: Set<BlockchainSdk.Blockchain>
    ) throws(WalletConnectDAppProposalLoadingError) {
        guard requiredBlockchains.isEmpty, optionalBlockchains.isEmpty else {
            return
        }

        let unsupportedOptionalBlockchainNames = WalletConnectDAppSessionProposalMapper.mapUnsupportedOptionalBlockchainNames(
            from: reownSessionProposal
        )

        guard unsupportedOptionalBlockchainNames.isEmpty else {
            throw WalletConnectDAppProposalLoadingError.unsupportedBlockchains(
                .init(
                    proposalID: reownSessionProposal.id,
                    dAppName: reownSessionProposal.proposer.name,
                    blockchainNames: unsupportedOptionalBlockchainNames.sorted()
                )
            )
        }
    }
}
