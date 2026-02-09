//
//  ReownWalletConnectDAppDataService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
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
        let (reownSessionProposal, reownVerifyContext) = try await openSessionWithForcedTimeout(uri: uri)

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

        let dAppDomain = try WalletConnectDAppSessionProposalMapper.mapDomainURL(
            from: reownSessionProposal,
            context: reownVerifyContext
        )
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
            dAppWalletConnectionRequestFactory: { [reownSessionProposal] selectedBlockchains, selectedUserWallet
                throws(WalletConnectDAppProposalApprovalError) in

                func caipReference(for domainBlockchain: BlockchainSdk.Blockchain) -> String? {
                    domainBlockchain.networkId == Self.solanaDomainNetworkID
                        ? specificSolanaCAIPReference
                        : nil
                }

                let reownSessionNamespaces: [String: SessionNamespace]
                let walletFlowAccounts = selectedBlockchains.flatMap {
                    WalletConnectAccountsMapper.map(
                        from: $0,
                        userWalletModel: selectedUserWallet,
                        preferredCAIPReference: caipReference(for: $0)
                    )
                }

                do {
                    reownSessionNamespaces = try AutoNamespaces.build(
                        sessionProposal: reownSessionProposal,
                        chains: selectedBlockchains.compactMap {
                            WalletConnectBlockchainMapper.mapFromDomain($0, preferredCAIPReference: caipReference(for: $0))
                        },
                        methods: WalletConnectDAppSessionProposalMapper.mapAllMethods(from: reownSessionProposal),
                        events: WalletConnectDAppSessionProposalMapper.mapAllEvents(from: reownSessionProposal),
                        accounts: walletFlowAccounts
                    )
                } catch {
                    throw WalletConnectDAppProposalApprovalError.invalidConnectionRequest(error)
                }

                let domainNamespaces = WalletConnectSessionNamespaceMapper.mapToDomain(reownSessionNamespaces)
                return WalletConnectDAppConnectionRequest(
                    proposalID: reownSessionProposal.id,
                    namespaces: domainNamespaces
                )
            },
            dAppAccountConnectionRequestFactory: { [reownSessionProposal] selectedBlockchains, selectedAccount, wcAccountsWalletModelProvider
                throws(WalletConnectDAppProposalApprovalError) in

                func caipReference(for domainBlockchain: BlockchainSdk.Blockchain) -> String? {
                    domainBlockchain.networkId == Self.solanaDomainNetworkID
                        ? specificSolanaCAIPReference
                        : nil
                }

                let reownSessionNamespaces: [String: SessionNamespace]
                let accountFlowAccounts = selectedBlockchains.flatMap {
                    WalletConnectAccountsMapper.map(
                        from: $0,
                        wcAccountsWalletModelProvider: wcAccountsWalletModelProvider,
                        preferredCAIPReference: caipReference(for: $0),
                        accountId: selectedAccount.id.walletConnectIdentifierString
                    )
                }

                do {
                    reownSessionNamespaces = try AutoNamespaces.build(
                        sessionProposal: reownSessionProposal,
                        chains: selectedBlockchains.compactMap {
                            WalletConnectBlockchainMapper.mapFromDomain($0, preferredCAIPReference: caipReference(for: $0))
                        },
                        methods: WalletConnectDAppSessionProposalMapper.mapAllMethods(from: reownSessionProposal),
                        events: WalletConnectDAppSessionProposalMapper.mapAllEvents(from: reownSessionProposal),
                        accounts: accountFlowAccounts
                    )
                } catch {
                    throw WalletConnectDAppProposalApprovalError.invalidConnectionRequest(error)
                }

                let domainNamespaces = WalletConnectSessionNamespaceMapper.mapToDomain(reownSessionNamespaces)
                return WalletConnectDAppConnectionRequest(
                    proposalID: reownSessionProposal.id,
                    namespaces: domainNamespaces
                )
            }
        )

        return (dAppData, sessionProposal)
    }

    // [REDACTED_TODO_COMMENT]
    private func openSessionWithForcedTimeout(
        uri: WalletConnectRequestURI
    ) async throws(WalletConnectDAppProposalLoadingError) -> (Session.Proposal, VerifyContext?) {
        try await withCheckedContinuation { continuation in
            Task {
                await self.innerOpenSessionWithForcedTimeout(uri: uri, continuation: continuation)
            }
        }.get()
    }

    private func innerOpenSessionWithForcedTimeout(
        uri: WalletConnectRequestURI,
        continuation: CheckedContinuation<Result<(Session.Proposal, VerifyContext?), WalletConnectDAppProposalLoadingError>, Never>
    ) async {
        let gate = LockGate()

        await withTaskGroup(of: Void.self) { [weak self] taskGroup in
            guard let self else {
                gate.run { continuation.resume(returning: .failure(WalletConnectDAppProposalLoadingError.cancelledByUser)) }
                return
            }

            taskGroup.addTask {
                do throws(WalletConnectDAppProposalLoadingError) {
                    let result = try await self.openSession(uri: uri)
                    gate.run { continuation.resume(returning: .success(result)) }
                } catch {
                    gate.run { continuation.resume(returning: .failure(error)) }
                }
            }

            taskGroup.addTask {
                do {
                    let nanoseconds = UInt64(Constants.pairingTaskTimeout * Double(NSEC_PER_SEC))
                    try await Task.sleep(nanoseconds: nanoseconds)
                    gate.run { continuation.resume(returning: .failure(WalletConnectDAppProposalLoadingError.pairingTimeout)) }
                } catch {
                    gate.run { continuation.resume(returning: .failure(WalletConnectDAppProposalLoadingError.cancelledByUser)) }
                }
            }

            defer { taskGroup.cancelAll() }
            await taskGroup.next()
        }
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

// MARK: - Nested types

extension ReownWalletConnectDAppDataService {
    private enum Constants {
        static let pairingTaskTimeout: TimeInterval = 30
    }

    @available(*, deprecated, message: "replace with general purpose forced-timeout function in https://tangem.atlassian.net/browse/[REDACTED_INFO]")
    private final class LockGate {
        private var isResumed = false
        private let lock = NSLock()

        func run(_ action: () -> Void) {
            lock.lock()
            defer { lock.unlock() }

            guard !isResumed else { return }
            isResumed = true
            action()
        }
    }
}
