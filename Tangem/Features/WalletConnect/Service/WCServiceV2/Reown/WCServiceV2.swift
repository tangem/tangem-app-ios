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

public typealias WalletConnectV2URI = WalletConnectURI

final class WCServiceV2 {
    @Injected(\.connectedDAppRepository) private var connectedDAppRepository: any WalletConnectConnectedDAppRepository
    @Injected(\.userWalletRepository) private var userWalletRepository: any UserWalletRepository

    private var sessionProposalContinuationStorage = SessionProposalContinuationsStorage()

    private let transactionsFilter = WCTransactionsFilter()
    private let transactionRequestSubject = PassthroughSubject<Result<WCHandleTransactionData, any Error>, Never>()
    private var bag = Set<AnyCancellable>()
    private var walletModelsCancellables = [UserWalletId: AnyCancellable]()
    private var walletModelsSnapshots = [String: Set<Blockchain>]()

    private let walletKitClient: ReownWalletKit.WalletKitClient
    private let wcHandlersService: WCHandlersService
    private var walletConnectEventsService: WalletConnectEventsService?

    private let balancesToObserve: [Blockchain]

    private var lastConnectedDAppsSnapshot: [WalletConnectConnectedDApp] = []
    private var balancesCancellables: [String: AnyCancellable] = [:]
    private var balancesWalletModelIds: [String: WalletModelId] = [:]

    var transactionRequestPublisher: AnyPublisher<Result<WCHandleTransactionData, any Error>, Never> {
        transactionRequestSubject.eraseToAnyPublisher()
    }

    init(
        walletKitClient: WalletKitClient,
        wcHandlersService: WCHandlersService,
        balancesToObserve: [Blockchain]
    ) {
        self.walletKitClient = walletKitClient
        self.wcHandlersService = wcHandlersService
        self.balancesToObserve = balancesToObserve

        bind()
    }
}

// MARK: - Bind

private extension WCServiceV2 {
    func bind() {
        subscribeToWCPublishers()
        setupMessagesSubscriptions()
        subscribeToUserWalletEvents()
        subscribeToWalletModelsIfNeeded()
        subscribeToBalancesChange()
        observeConnectedDAppsRepository()
    }

    func observeConnectedDAppsRepository() {
        let task = Task { [weak self, connectedDAppRepository] in
            guard let self else { return }

            let stream = await connectedDAppRepository.makeDAppsStream()

            for await dApps in stream {
                guard !Task.isCancelled else { return }
                handleConnectedDAppsRepositoryYield(dApps)
            }
        }

        AnyCancellable { task.cancel() }.store(in: &bag)
    }

    func handleConnectedDAppsRepositoryYield(_ dApps: [WalletConnectConnectedDApp]) {
        lastConnectedDAppsSnapshot = dApps
        walletConnectEventsService?.handle(event: .dappConnected(dApps))
    }

    func subscribeToBalancesChange() {
        guard let selectedUserWalletModel = userWalletRepository.selectedModel else {
            return
        }

        for blockchain in balancesToObserve {
            let networkId = blockchain.networkId

            guard let walletModel = selectedUserWalletModel.wcWalletModelProvider.getModel(with: networkId) else {
                balancesCancellables[networkId]?.cancel()
                balancesCancellables[networkId] = nil
                balancesWalletModelIds[networkId] = nil
                continue
            }

            // Keep subscriber alive regardless of connected dApps.
            // Recreate only when the underlying wallet model changes (e.g. selected wallet switched).
            guard balancesWalletModelIds[networkId] != walletModel.id else {
                continue
            }

            balancesWalletModelIds[networkId] = walletModel.id
            balancesCancellables[networkId]?.cancel()

            balancesCancellables[networkId] = walletModel
                .availableBalanceProvider
                .balanceTypePublisher
                .map(\.value)
                .removeDuplicates()
                .sink { [weak self] _ in
                    guard let self else { return }
                    walletConnectEventsService?.handle(event: .balanceChanged(lastConnectedDAppsSnapshot, blockchain))
                }
        }
    }

    func subscribeToUserWalletEvents() {
        userWalletRepository
            .eventProvider
            .withWeakCaptureOf(self)
            .sink { wcService, event in
                switch event {
                case .deleted(let userWalletIds):
                    userWalletIds.forEach {
                        wcService.walletModelsSnapshots[$0.stringValue] = nil
                        wcService.disconnectAllSessionsForUserWallet(with: $0.stringValue)
                        wcService.cancelWalletModelsSubscription(for: $0)
                    }

                case .selected(let userWalletId), .unlockedWallet(let userWalletId):
                    wcService.subscribeToWalletModels(for: userWalletId)
                    wcService.subscribeToBalancesChange()

                case .inserted(let userWalletId):
                    wcService.subscribeToWalletModels(for: userWalletId)
                    wcService.subscribeToBalancesChange()

                case .unlocked:
                    wcService.subscribeToWalletModelsIfNeeded()
                    wcService.subscribeToBalancesChange()

                case .locked:
                    break
                }
            }
            .store(in: &bag)
    }

    func subscribeToWalletModelsIfNeeded() {
        userWalletRepository.models.forEach { model in
            subscribeToWalletModels(for: model.userWalletId)
        }
    }

    func subscribeToWCPublishers() {
        walletKitClient
            .sessionProposalPublisher
            .sink { [weak self] sessionProposal, verifyContext in
                WCLogger.info(LoggerStrings.sessionProposal(sessionProposal, verifyContext))
                Analytics.debugLog(
                    eventInfo: Analytics.WalletConnectDebugEvent.receiveSessionProposal(
                        name: sessionProposal.proposer.name,
                        dAppURL: verifyContext?.origin ?? sessionProposal.proposer.url
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
                    guard await self.transactionsFilter.filter(request) else {
                        WCLogger.info("Filtered out duplicate or invalid request: \(request)")
                        return
                    }

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

    func subscribeToWalletModels(for userWalletId: UserWalletId) {
        cancelWalletModelsSubscription(for: userWalletId)

        guard let userWalletModel = userWalletRepository.models[userWalletId] else {
            return
        }

        walletModelsCancellables[userWalletId] = AccountsFeatureAwareWalletModelsResolver
            .walletModelsPublisher(for: userWalletModel)
            .map { walletModels in
                walletModels.compactMap { walletModel -> Blockchain? in
                    guard walletModel.tokenItem.isBlockchain else {
                        return nil
                    }

                    return walletModel.tokenItem.blockchain
                }
            }
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { wcService, blockchains in
                wcService.handleWalletModelsUpdate(blockchains: blockchains, for: userWalletId.stringValue)
            }
    }

    func cancelWalletModelsSubscription(for userWalletId: UserWalletId) {
        walletModelsCancellables[userWalletId]?.cancel()
        walletModelsCancellables[userWalletId] = nil
    }

    func handleWalletModelsUpdate(blockchains: [Blockchain], for userWalletId: String) {
        let newSnapshot = Set(blockchains)
        defer { walletModelsSnapshots[userWalletId] = newSnapshot }

        guard let selectedUserWallet = userWalletRepository.selectedModel,
              selectedUserWallet.userWalletId.stringValue == userWalletId,
              let oldSnapshot = walletModelsSnapshots[userWalletId]
        else {
            return
        }

        let removedBlockchains = oldSnapshot.subtracting(newSnapshot)

        removedBlockchains.forEach {
            handleHiddenBlockchainFromCurrentUserWallet($0)
        }
    }
}

// MARK: - Events

extension WCServiceV2 {
    func setWalletConnectEventsService(_ walletConnectEventsService: WalletConnectEventsService) {
        self.walletConnectEventsService = walletConnectEventsService
    }

    func emitEvent(_ event: Session.Event, on blockchain: BlockchainSdk.Blockchain) {
        runTask { [weak self, walletKitClient] in
            guard let self else { return }

            guard let chainId = WalletConnectBlockchainMapper.mapFromDomain(blockchain) else {
                WCLogger.error(error: "Failed to emit WC event. Unsupported blockchain: \(blockchain)")
                return
            }

            let allDApps = (try? await connectedDAppRepository.getAllDApps()) ?? []

            let topics = Set(
                allDApps
                    .filter { dApp in
                        dApp.dAppBlockchains.contains(where: { $0.blockchain.networkId == blockchain.networkId })
                    }
                    .map(\.session.topic)
            )

            guard topics.isNotEmpty else {
                WCLogger.info("No WC sessions found for blockchain: \(blockchain)")
                return
            }

            await withTaskGroup(of: Void.self) { taskGroup in
                for topic in topics {
                    taskGroup.addTask {
                        do {
                            try await walletKitClient.emit(topic: topic, event: event, chainId: chainId)
                        } catch {
                            WCLogger.error("Failed to emit WC event for topic: \(topic)", error: error)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Disconnect

extension WCServiceV2 {
    func disconnectAllSessionsForUserWallet(with userWalletId: String) {
        runTask { [weak self, walletKitClient] in
            guard let self else { return }

            let deletedDApps = (try? await connectedDAppRepository.deleteDApps(forUserWalletId: userWalletId)) ?? []

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
            let connectedDApps = (try? await connectedDAppRepository.getDApps(forUserWalletId: selectedUserWallet.userWalletId.stringValue)) ?? []

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
            .blockchain: blockchainName,
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
