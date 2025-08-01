//
//  WCServiceV2.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import ReownWalletKit
import BlockchainSdk
import TangemFoundation

final class WCServiceV2 {
    @Injected(\.connectedDAppRepository) private var connectedDAppRepository: any WalletConnectConnectedDAppRepository

    private var sessionProposalContinuationStorage = SessionProposalContinuationsStorage()

    private let transactionRequestSubject = PassthroughSubject<WCHandleTransactionData, WalletConnectV2Error>()
    private var bag = Set<AnyCancellable>()

    private let walletKitClient: ReownWalletKit.WalletKitClient
    private let wcHandlersService: WCHandlersService

    // MARK: - Public properties

    var transactionRequestPublisher: AnyPublisher<WCHandleTransactionData, WalletConnectV2Error> {
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
            .receiveOnMain()
            .sink { [weak self, walletKitClient] request, context in
                guard let self else { return }

                WCLogger.info("Receive message request: \(request) with verify context: \(String(describing: context))")

                Task {
                    let connectedDApp: WalletConnectConnectedDApp

                    do {
                        connectedDApp = try await self.connectedDAppRepository.getDApp(with: request.topic)
                    } catch {
                        let errorMessage = "Session for topic \(request.topic) not found."
                        WCLogger.error(error: errorMessage)
                        try? await walletKitClient.respond(
                            topic: request.topic,
                            requestId: request.id,
                            response: .error(.init(code: 0, message: error.localizedDescription))
                        )
                        return
                    }

                    do {
                        let validatedRequest = try await self.wcHandlersService.validate(request)
                        let transactionDTO = try await self.wcHandlersService.makeHandleTransactionDTO(
                            from: validatedRequest,
                            connectedBlockchains: connectedDApp.blockchains
                        )

                        self.transactionRequestSubject.send(
                            .init(
                                from: transactionDTO,
                                validatedRequest: validatedRequest,
                                respond: walletKitClient.respond
                            )
                        )
                    } catch {
                        try? await walletKitClient.respond(
                            topic: request.topic,
                            requestId: request.id,
                            response: .error(.init(code: 0, message: error.localizedDescription))
                        )
                        self.logSignatureRequestReceiveFailed(with: error, request: request, connectedDApp: connectedDApp)
                    }
                }
            }
            .store(in: &bag)
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
                            WCLogger.error(LoggerStrings.failedDisconnectSessions(userWalletId), error: error)
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
}

// MARK: - Analytics

extension WCServiceV2 {
    func logSignatureRequestReceiveFailed(with error: some Error, request: Request, connectedDApp: WalletConnectConnectedDApp) {
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
