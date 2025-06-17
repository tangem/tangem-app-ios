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
    // MARK: - Dependencies

    @Injected(\.walletConnectSessionsStorage) private var sessionsStorage: WalletConnectSessionsStorage
    @Injected(\.keysManager) private var keysManager: KeysManager

    // MARK: - Public properties

    var newSessions: AsyncStream<[WalletConnectSavedSession]> {
        get async {
            await sessionsStorage.sessions
        }
    }

    var transactionRequestPublisher: AnyPublisher<WCHandleTransactionData, WalletConnectV2Error> {
        transactionRequestSubject.eraseToAnyPublisher()
    }

    // MARK: - Private properties

    private var sessionProposalContinuationStorage = SessionProposalContinuationsStorage()

    private let transactionRequestSubject = PassthroughSubject<WCHandleTransactionData, WalletConnectV2Error>()
    private var bag = Set<AnyCancellable>()

    private let factory = WalletConnectV2DefaultSocketFactory()
    private let wcHandlersService: WCHandlersService

    init(wcHandlersService: WCHandlersService) {
        self.wcHandlersService = wcHandlersService

        guard FeatureProvider.isAvailable(.walletConnectUI) else { return }

        Networking.configure(
            groupIdentifier: AppEnvironment.current.suiteName,
            projectId: keysManager.walletConnectProjectId,
            socketFactory: factory,
            socketConnectionType: .automatic
        )

        do {
            try configureWalletKit()
        } catch {
            WCLogger.error(LoggerStrings.walletConnectRedirectFailure, error: error)
        }

        bind()
    }

    func initialize() {
        runTask { [weak self] in
            await self?.sessionsStorage.loadSessions()
        }
    }

    private func configureWalletKit() throws {
        let metadata = try AppMetadata(
            name: AppMetadata.tangemAppName,
            description: AppMetadata.tangemAppDescription,
            url: AppMetadata.tangemURL,
            icons: AppMetadata.tangemIconURLs,
            redirect: AppMetadata.makeTangemAppRedirect()
        )

        WalletKit.configure(metadata: metadata, crypto: WalletConnectCryptoProvider())
    }
}

// MARK: - Bind

private extension WCServiceV2 {
    func bind() {
        subscribeToWCPublishers()
        setupMessagesSubscriptions()
    }

    func subscribeToWCPublishers() {
        WalletKit.instance.sessionProposalPublisher
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
                        for: sessionProposal.pairingTopic
                    )
                }
            }
            .store(in: &bag)

        WalletKit.instance.sessionDeletePublisher
            .asyncMap { [weak self] topic, reason in
                WCLogger.info(LoggerStrings.receiveDeleteMessage(topic, reason))

                guard
                    let self,
                    let session = await sessionsStorage.session(with: topic)
                else {
                    WCLogger.info(LoggerStrings.receiveDeleteMessageSessionNotFound(topic, reason))
                    return
                }

                Analytics.log(
                    event: .walletConnectDAppDisconnected,
                    params: [
                        .dAppName: session.sessionInfo.dAppInfo.name,
                        .dAppUrl: session.sessionInfo.dAppInfo.url,
                    ]
                )

                WCLogger.info(LoggerStrings.sessionWasFound(topic))
                await sessionsStorage.remove(session)
            }
            .sink()
            .store(in: &bag)
    }

    func setupMessagesSubscriptions() {
        WalletKit.instance.sessionRequestPublisher
            .receiveOnMain()
            .sink { [weak self] request, context in
                guard let self else { return }

                WCLogger.info("Receive message request: \(request) with verify context: \(String(describing: context))")

                Task {
                    do {
                        let validatedRequest = try await self.wcHandlersService.validate(request)
                        let transactionDTO = try await self.wcHandlersService.makeHandleTransactionDTO(
                            from: validatedRequest
                        )

                        self.transactionRequestSubject.send(
                            .init(
                                from: transactionDTO,
                                validatedRequest: validatedRequest,
                                respond: WalletKit.instance.respond
                            )
                        )
                    } catch {
                        try? await WalletKit.instance.respond(
                            topic: request.topic,
                            requestId: request.id,
                            response: .error(.init(code: 0, message: error.localizedDescription))
                        )
                    }
                }
            }
            .store(in: &bag)
    }
}

// MARK: - Disconnect

extension WCServiceV2 {
    func disconnectSession(with id: Int) async {
        guard let session = await sessionsStorage.session(with: id) else {
            WCLogger.error(error: LoggerStrings.failedToFindSession(id))
            return
        }

        do {
            WCLogger.info(LoggerStrings.attemptToDisconnect(session.topic))
            try await WalletKit.instance.disconnect(topic: session.topic)

            WCLogger.info(LoggerStrings.sessionDisconnected(session.topic))
            await sessionsStorage.remove(session)
        } catch {
            let internalError = WalletConnectV2ErrorMappingUtils().mapWCv2Error(error)

            switch internalError {
            case .sessionForTopicNotFound, .symmetricKeyForTopicNotFound:
                WCLogger.error(LoggerStrings.failedToRemoveSession(session.topic), error: internalError)
                await sessionsStorage.remove(session)
                return
            default:
                break
            }

            WCLogger.error(LoggerStrings.failedToDisconnectSession(session.topic), error: error)
        }
    }

    func disconnectAllSessionsForUserWallet(with userWalletId: String) {
        runTask { [weak self] in
            guard let self else { return }

            let removedSessions = await sessionsStorage.removeSessions(for: userWalletId)

            await withTaskGroup(of: Void.self) { taskGroup in
                for session in removedSessions {
                    taskGroup.addTask {
                        do {
                            try await WalletKit.instance.disconnect(topic: session.topic)
                        } catch {
                            WCLogger.error(LoggerStrings.failedDisconnectSessions(userWalletId), error: error)
                        }
                    }
                }
            }
        }
    }

    private func disconnect(topic: String) async {
        do {
            try await WalletKit.instance.disconnect(topic: topic)
            WCLogger.info(LoggerStrings.successDisconnectDelete(topic))
        } catch {
            WCLogger.error(LoggerStrings.failedDisconnectDelete(topic), error: error)
        }
    }
}

// MARK: - Refac

extension WCServiceV2 {
    func openSession(with uri: WalletConnectV2URI, source: Analytics.WalletConnectSessionSource) async throws -> Session.Proposal {
        WCLogger.info(LoggerStrings.tryingToPairClient(uri))
        Analytics.log(event: .walletConnectSessionInitiated, params: [Analytics.ParameterKey.source: source.rawValue])

        return try await withCheckedThrowingContinuation { [weak self] continuation in
            Task {
                await self?.sessionProposalContinuationStorage.store(continuation: continuation, for: uri.topic)

                do {
                    try Task.checkCancellation()
                    try await WalletKit.instance.pair(uri: uri)
                    WCLogger.info(LoggerStrings.establishedPair(uri))
                } catch {
                    await self?.sessionProposalContinuationStorage.resumeThrowing(error: error, for: uri.topic)
                    await self?.disconnect(topic: uri.topic)
                    WCLogger.error(LoggerStrings.failedToConnect(uri), error: error)
                    Analytics.log(.walletConnectSessionFailed)
                }
            }
        }
    }

    // [REDACTED_TODO_COMMENT]
    func approveSessionProposal(with proposalID: String, namespaces: [String: SessionNamespace], _ userWalletID: String) async throws {
        WCLogger.info(LoggerStrings.namespacesToApprove(namespaces))
        let session = try await WalletKit.instance.approve(proposalId: proposalID, namespaces: namespaces)

        WCLogger.info(LoggerStrings.sessionEstablished(session))
        let savedSession = session.mapToWCSavedSession(with: userWalletID)
        WCLogger.info(LoggerStrings.savedSession(savedSession.topic, savedSession.sessionInfo.dAppInfo.url))
        await sessionsStorage.save(savedSession)
    }

    func rejectSessionProposal(with proposalID: String, reason: RejectionReason) async throws {
        do {
            try await WalletKit.instance.rejectSession(proposalId: proposalID, reason: reason)
            WCLogger.info(LoggerStrings.userRejectWC)
        } catch {
            WCLogger.error(LoggerStrings.failedToRejectWC, error: error)
            throw error
        }
    }
}

// MARK: - Session.Proposal continuations storage

extension WCServiceV2 {
    private actor SessionProposalContinuationsStorage {
        private var pairingTopicToSessionProposalContinuation = [String: CheckedContinuation<Session.Proposal, any Error>?]()

        func store(continuation: CheckedContinuation<Session.Proposal, any Error>, for topic: String) {
            pairingTopicToSessionProposalContinuation[topic] = continuation
        }

        func resume(proposal: Session.Proposal, for topic: String) {
            pairingTopicToSessionProposalContinuation[topic]??.resume(returning: proposal)
            pairingTopicToSessionProposalContinuation[topic] = nil
        }

        func resumeThrowing(error: some Error, for topic: String) {
            pairingTopicToSessionProposalContinuation[topic]??.resume(throwing: error)
            pairingTopicToSessionProposalContinuation[topic] = nil
        }
    }
}

// MARK: - Constants

private extension AppMetadata {
    static let tangemAppName: String = "Tangem iOS"

    static let tangemAppDescription: String = "Tangem is a card-shaped self-custodial cold hardware wallet"

    static let tangemURL: String = "https://tangem.com"

    static let tangemIconURLs = [
        "https://user-images.githubusercontent.com/24321494/124071202-72a00900-da58-11eb-935a-dcdab21de52b.png",
    ]

    static func makeTangemAppRedirect() throws -> AppMetadata.Redirect {
        try AppMetadata.Redirect(
            native: IncomingActionConstants.universalLinkScheme,
            universal: IncomingActionConstants.tangemDomain
        )
    }
}
