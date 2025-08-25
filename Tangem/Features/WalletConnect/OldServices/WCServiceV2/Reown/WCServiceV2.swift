//
//  WCServiceV2.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import ReownWalletKit
import enum BlockchainSdk.Blockchain
import TangemFoundation

final class WCServiceV2 {
    @Injected(\.connectedDAppRepository) private var connectedDAppRepository: any WalletConnectConnectedDAppRepository
    @Injected(\.userWalletRepository) private var userWalletRepository: any UserWalletRepository

    private var sessionProposalContinuationStorage = SessionProposalContinuationsStorage()

    private let transactionRequestSubject = PassthroughSubject<Result<WCHandleTransactionData, any Error>, Never>()
    private var bag = Set<AnyCancellable>()

    private let walletKitClient: ReownWalletKit.WalletKitClient
    private let wcHandlersService: WCHandlersService

    var transactionRequestPublisher: AnyPublisher<Result<WCHandleTransactionData, any Error>, Never> {
        transactionRequestSubject.eraseToAnyPublisher()
    }

    init(walletKitClient: WalletKitClient, wcHandlersService: WCHandlersService) {
        self.walletKitClient = walletKitClient
        self.wcHandlersService = wcHandlersService

        guard FeatureProvider.isAvailable(.walletConnectUI) else { return }

        bind()
    }
}

// MARK: - Bind

private extension WCServiceV2 {
    func bind() {
        subscribeToWCPublishers()
        setupMessagesSubscriptions()
    }

    func subscribeToWCPublishers() {
        walletKitClient
            .sessionProposalPublisher
            .sink { [weak self] sessionProposal, verifyContext in
                WCLogger.info(LoggerStrings.sessionProposal(sessionProposal, verifyContext))
                Analytics.debugLog(
                    eventInfo: Analytics.WalletConnectDebugEvent.receiveSessionProposal(
                        name: sessionProposal.proposer.name,
                        dAppURL: sessionProposal.proposer.url
                    )
                )

                Task {
                    await self?.sessionProposalContinuationStorage.resume(
                        proposal: sessionProposal,
                        context: verifyContext,
                        for: sessionProposal.pairingTopic
                    )
                }
            }
            .store(in: &bag)

        walletKitClient
            .sessionDeletePublisher
            .asyncMap { [connectedDAppRepository] topic, reason in
                WCLogger.info(LoggerStrings.receiveDeleteMessage(topic, reason))

                do {
                    try await connectedDAppRepository.deleteDApp(with: topic)
                    WCLogger.info(LoggerStrings.sessionWasFound(topic))
                } catch {
                    WCLogger.info(LoggerStrings.receiveDeleteMessageSessionNotFound(topic, reason))
                }
            }
            .sink()
            .store(in: &bag)
    }

    func setupMessagesSubscriptions() {
        walletKitClient
            .sessionRequestPublisher
            .removeDuplicates { lhs, rhs in
                lhs.request == rhs.request && lhs.context == rhs.context
            }
            .receiveOnMain()
            .sink { [weak self, walletKitClient] request, context in

                guard let self else { return }

                WCLogger.info("Receive message request: \(request) with verify context: \(String(describing: context))")

                Task {
                    if Self.checkIfShouldIgnore(transactionRequest: request) {
                        WCLogger.info("Received a transaction with \(request.method) method. Rejecting and ignoring further handling.")
                        await self.reject(transactionRequest: request)
                        return
                    }

                    let connectedDApp: WalletConnectConnectedDApp

                    do {
                        connectedDApp = try await self.connectedDAppRepository.getDApp(with: request.topic)
                    } catch {
                        let errorMessage = "Session for topic \(request.topic) not found."
                        WCLogger.error(error: errorMessage)
                        await self.reject(transactionRequest: request)
                        self.transactionRequestSubject.send(.failure(error))
                        return
                    }

                    do {
                        let validatedRequest = try self.wcHandlersService.validate(request: request, forConnectedDApp: connectedDApp)

                        let transactionDTO = try self.wcHandlersService.makeHandleTransactionDTO(
                            from: validatedRequest,
                            connectedDApp: connectedDApp
                        )

                        let handleTransactionData = WCHandleTransactionData(
                            from: transactionDTO,
                            validatedRequest: validatedRequest,
                            respond: walletKitClient.respond
                        )

                        self.transactionRequestSubject.send(.success(handleTransactionData))
                    } catch {
                        WCLogger.error("WCHandleTransactionDTO creation failed: ", error: error)
                        await self.reject(transactionRequest: request)

                        self.transactionRequestSubject.send(.failure(error))
                        self.logSignatureRequestReceiveFailed(with: error, request: request, connectedDApp: connectedDApp)
                    }
                }
            }
            .store(in: &bag)
    }

    private static func checkIfShouldIgnore(transactionRequest request: Request) -> Bool {
        let methodIsNotSupported = WalletConnectMethod(rawValue: request.method) == nil
        let methodHasWalletPrefix = request.method.hasPrefix("wallet_")

        return methodIsNotSupported && methodHasWalletPrefix
    }

    private func reject(transactionRequest: Request) async {
        do {
            try await walletKitClient.respond(
                topic: transactionRequest.topic,
                requestId: transactionRequest.id,
                response: .error(.init(code: 0, message: ""))
            )
        } catch {
            let errorMessage = "Failed to reject request with topic: \(transactionRequest.topic) for method: \(transactionRequest.method)"
            WCLogger.error(errorMessage, error: error)
        }
    }
}

// MARK: - Disconnect

extension WCServiceV2 {
    func disconnectAllSessionsForUserWallet(with userWalletId: String) {
        runTask { [weak self, walletKitClient] in
            guard let self else { return }

            let deletedDApps = (try? await connectedDAppRepository.deleteDApps(forUserWalletID: userWalletId)) ?? []

            await withTaskGroup(of: Void.self) { taskGroup in
                for dApp in deletedDApps {
                    taskGroup.addTask {
                        do {
                            try await walletKitClient.disconnect(topic: dApp.session.topic)
                            self.logDAppDisconnected(dApp)
                        } catch {
                            WCLogger.error(LoggerStrings.failedToDisconnectSession(dApp.session.topic), error: error)
                        }
                    }
                }
            }
        }
    }

    func disconnectSession(withTopic topic: String) async throws {
        do {
            try await walletKitClient.disconnect(topic: topic)
            WCLogger.info(LoggerStrings.successDisconnectDelete(topic))
        } catch {
            WCLogger.error(LoggerStrings.failedDisconnectDelete(topic), error: error)
            throw error
        }
    }

    func handleHiddenBlockchainFromCurrentUserWallet(_ blockchain: BlockchainSdk.Blockchain) {
        guard let selectedUserWallet = userWalletRepository.selectedModel else { return }

        Task { [connectedDAppRepository] in
            let connectedDApps = (try? await connectedDAppRepository.getDApps(for: selectedUserWallet.userWalletId.stringValue)) ?? []

            let dAppsToDisconnect = connectedDApps.filter { dApp in
                let hasOnlyOneHiddenBlockchain = dApp.dAppBlockchains.count == 1
                    && dApp.dAppBlockchains[0].blockchain.networkId == blockchain.networkId

                let hasRequiredHiddenBlockchain = dApp.dAppBlockchains
                    .filter(\.isRequired)
                    .contains(where: { $0.blockchain.networkId == blockchain.networkId })

                return hasOnlyOneHiddenBlockchain || hasRequiredHiddenBlockchain
            }

            guard dAppsToDisconnect.isNotEmpty else {
                return
            }

            let dAppsToDisconnectNames = dAppsToDisconnect.map(\.dAppData.name).joined(separator: ", ")

            WCLogger.info("\(blockchain.displayName) blockchain causes \(dAppsToDisconnectNames) dApps to be disconnected.")

            async let repositoryTask: Void = connectedDAppRepository.delete(dApps: dAppsToDisconnect)

            async let walletKitTask: Void = withTaskGroup(of: Void.self) { [weak self] taskGroup in
                for dApp in dAppsToDisconnect {
                    taskGroup.addTask {
                        try? await self?.disconnectSession(withTopic: dApp.session.topic)
                    }
                }
            }

            do {
                try await repositoryTask
            } catch {
                WCLogger.error("Persistence update failed caused by hiding \(blockchain.displayName) blockchain.", error: error)
            }

            await walletKitTask
            WCLogger.info("\(dAppsToDisconnectNames) dApps disconnect caused by hiding \(blockchain.displayName) blockchain finished.")
        }
    }
}

// MARK: - Refac

extension WCServiceV2 {
    func openSession(with uri: WalletConnectV2URI) async throws -> (Session.Proposal, VerifyContext?) {
        WCLogger.info(LoggerStrings.tryingToPairClient(uri))

        return try await withCheckedThrowingContinuation { [weak self] continuation in
            Task {
                await self?.sessionProposalContinuationStorage.store(continuation: continuation, for: uri.topic)

                do {
                    try Task.checkCancellation()
                    try await self?.walletKitClient.pair(uri: uri)
                    WCLogger.info(LoggerStrings.establishedPair(uri))
                } catch {
                    await self?.sessionProposalContinuationStorage.resumeThrowing(error: error, for: uri.topic)
                    try? await self?.disconnectSession(withTopic: uri.topic)
                    WCLogger.error(LoggerStrings.failedToConnect(uri), error: error)
                }
            }
        }
    }

    func approveSessionProposal(with proposalID: String, namespaces: [String: SessionNamespace]) async throws -> Session {
        WCLogger.info(LoggerStrings.namespacesToApprove(namespaces))
        let session = try await walletKitClient.approve(proposalId: proposalID, namespaces: namespaces)
        WCLogger.info(LoggerStrings.sessionEstablished(session))
        return session
    }

    func rejectSessionProposal(with proposalID: String, reason: RejectionReason) async throws {
        do {
            try await walletKitClient.rejectSession(proposalId: proposalID, reason: reason)
            WCLogger.info(LoggerStrings.userRejectWC)
        } catch {
            WCLogger.error(LoggerStrings.failedToRejectWC, error: error)
            throw error
        }
    }

    func updateSession(withTopic topic: String, namespaces: [String: SessionNamespace]) async throws {
        try await walletKitClient.update(topic: topic, namespaces: namespaces)
    }
}

// MARK: - Analytics

extension WCServiceV2 {
    func logSignatureRequestReceiveFailed(with error: some Error, request: Request, connectedDApp: WalletConnectConnectedDApp) {
        // [REDACTED_USERNAME], wallet_addEthereumChain and wallet_switchEthereumChain methods are heavily relying on error propagation.
        // No need to report to analytics services.
        switch WalletConnectMethod(rawValue: request.method) {
        case .addChain, .switchChain:
            return
        default:
            break
        }

        let blockchainName = WalletConnectBlockchainMapper.mapToDomain(request.chainId)?.displayName ?? request.chainId.absoluteString

        let params: [Analytics.ParameterKey: String] = [
            .methodName: request.method,
            .walletConnectDAppName: connectedDApp.dAppData.name,
            .walletConnectDAppUrl: connectedDApp.dAppData.domain.absoluteString,
            .walletConnectBlockchain: blockchainName,
            .errorCode: "\(error.universalErrorCode)",
        ]

        Analytics.log(event: .walletConnectSignatureRequestReceivedFailure, params: params)
    }

    func logDAppDisconnected(_ dApp: WalletConnectConnectedDApp) {
        Analytics.log(
            event: .walletConnectDAppDisconnected,
            params: [
                .walletConnectDAppName: dApp.dAppData.name,
                .walletConnectDAppUrl: dApp.dAppData.domain.absoluteString,
            ]
        )
    }
}

// MARK: - Session.Proposal continuations storage

extension WCServiceV2 {
    private actor SessionProposalContinuationsStorage {
        typealias ProposalWithContext = (Session.Proposal, VerifyContext?)

        private var pairingTopicToSessionProposalContinuation = [String: CheckedContinuation<ProposalWithContext, any Error>?]()

        func store(continuation: CheckedContinuation<ProposalWithContext, any Error>, for topic: String) {
            pairingTopicToSessionProposalContinuation[topic] = continuation
        }

        func resume(proposal: Session.Proposal, context: VerifyContext?, for topic: String) {
            pairingTopicToSessionProposalContinuation[topic]??.resume(returning: (proposal: proposal, context: context))
            pairingTopicToSessionProposalContinuation[topic] = nil
        }

        func resumeThrowing(error: some Error, for topic: String) {
            pairingTopicToSessionProposalContinuation[topic]??.resume(throwing: error)
            pairingTopicToSessionProposalContinuation[topic] = nil
        }
    }
}
