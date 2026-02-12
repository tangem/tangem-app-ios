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
    private var accountsMigrationTask: Task<Void, Never>?

    private let walletKitClient: ReownWalletKit.WalletKitClient
    private let wcHandlersService: WCHandlersService
    private lazy var savedSessionToAccountsMigrationService = WalletConnectAccountMigrationService(
        userWalletRepository: userWalletRepository,
        connectedDAppRepository: connectedDAppRepository,
        appSettings: AppSettings.shared
    )

    var transactionRequestPublisher: AnyPublisher<Result<WCHandleTransactionData, any Error>, Never> {
        transactionRequestSubject.eraseToAnyPublisher()
    }

    init(walletKitClient: WalletKitClient, wcHandlersService: WCHandlersService) {
        self.walletKitClient = walletKitClient
        self.wcHandlersService = wcHandlersService

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
    }

    func subscribeToUserWalletEvents() {
        userWalletRepository
            .eventProvider
            .withWeakCaptureOf(self)
            .sink { wcService, event in
                switch event {
                case .deleted(let userWalletIds, _):
                    userWalletIds.forEach {
                        wcService.walletModelsSnapshots[$0.stringValue] = nil
                        wcService.disconnectAllSessionsForUserWallet(with: $0.stringValue)
                        wcService.cancelModelSubscriptions(for: $0)
                    }

                case .selected(let userWalletId), .unlockedWallet(let userWalletId):
                    wcService.subscribeToWalletModels(for: userWalletId)

                case .inserted(let userWalletId):
                    wcService.subscribeToWalletModels(for: userWalletId)

                case .unlocked:
                    wcService.subscribeToWalletModelsIfNeeded()

                case .locked, .reordered:
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
                        connectedDApp = try await self.resolveConnectedDApp(for: request)
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

    private func resolveConnectedDApp(for request: Request) async throws -> WalletConnectConnectedDApp {
        let dApps = try await connectedDAppRepository.getDApps(with: request.topic)

        guard dApps.isNotEmpty else {
            throw WalletConnectDAppPersistenceError.notFound
        }

        guard let requestedAddress = extractRequestedAddress(from: request).map(normalizeAddress) else {
            return dApps[0]
        }

        guard dApps.count > 1 else {
            return resolveByAddressOrFallback(
                in: dApps[0],
                requestedAddress: requestedAddress,
                request: request
            )
        }

        return resolveAmongTopicDApps(
            dApps,
            requestedAddress: requestedAddress,
            request: request
        )
    }

    private func resolveAmongTopicDApps(
        _ dApps: [WalletConnectConnectedDApp],
        requestedAddress: String,
        request: Request
    ) -> WalletConnectConnectedDApp {
        if let matchedDApp = dApps.first(where: { sessionContainsAddress(requestedAddress, in: $0) }) {
            return matchedDApp
        }

        if let fallbackMatched = dApps.first(where: { canHandleAddressInAccountScope($0, requestedAddress: requestedAddress, request: request) }) {
            return fallbackMatched
        }

        return dApps[0]
    }

    private func sessionContainsAddress(_ requestedAddress: String, in dApp: WalletConnectConnectedDApp) -> Bool {
        dApp.session.namespaces
            .flatMap { $0.value.accounts }
            .contains(where: { normalizeAddress($0.address) == requestedAddress })
    }

    private func canHandleAddressInAccountScope(
        _ dApp: WalletConnectConnectedDApp,
        requestedAddress: String,
        request: Request
    ) -> Bool {
        guard case .v2(let dAppV2) = dApp else {
            return false
        }

        return accountCanHandleAddress(
            accountId: dAppV2.accountId,
            userWalletId: dAppV2.wrapped.userWalletID,
            requestedAddress: requestedAddress,
            request: request
        )
    }

    private func resolveByAddressOrFallback(
        in dApp: WalletConnectConnectedDApp,
        requestedAddress: String,
        request: Request
    ) -> WalletConnectConnectedDApp {
        let inSession = dApp.session.namespaces
            .flatMap { $0.value.accounts }
            .contains(where: { normalizeAddress($0.address) == requestedAddress })

        if inSession {
            return dApp
        }

        guard case .v2(let dAppV2) = dApp else {
            return dApp
        }

        if accountCanHandleAddress(
            accountId: dAppV2.accountId,
            userWalletId: dAppV2.wrapped.userWalletID,
            requestedAddress: requestedAddress,
            request: request
        ) {
            return dApp
        }

        guard
            let resolvedAccountId = resolveAccountIdForAddress(
                requestedAddress: requestedAddress,
                userWalletId: dAppV2.wrapped.userWalletID,
                request: request
            ),
            resolvedAccountId != dAppV2.accountId
        else {
            return dApp
        }

        return .v2(WalletConnectConnectedDAppV2(accountId: resolvedAccountId, wrapped: dAppV2.wrapped))
    }

    private func accountCanHandleAddress(
        accountId: String,
        userWalletId: String,
        requestedAddress: String,
        request: Request
    ) -> Bool {
        guard
            let userWalletModel = userWalletRepository.models.first(where: { $0.userWalletId.stringValue == userWalletId })
        else {
            return false
        }

        let blockchainNetworkId = WalletConnectBlockchainMapper.mapToDomain(request.chainId)?.networkId

        guard
            let cryptoAccount = userWalletModel.accountModelsManager.cryptoAccountModels.first(where: { account in
                account.id.walletConnectIdentifierString == accountId
            })
        else {
            return false
        }

        return cryptoAccount.walletModelsManager.walletModels.contains { walletModel in
            let blockchainMatches = blockchainNetworkId.map { walletModel.tokenItem.blockchain.networkId == $0 } ?? true
            let addressMatches = normalizeAddress(walletModel.walletConnectAddress) == requestedAddress

            return blockchainMatches && addressMatches
        }
    }

    private func resolveAccountIdForAddress(
        requestedAddress: String,
        userWalletId: String,
        request: Request
    ) -> String? {
        guard
            let userWalletModel = userWalletRepository.models.first(where: { $0.userWalletId.stringValue == userWalletId })
        else {
            return nil
        }

        let blockchainNetworkId = WalletConnectBlockchainMapper.mapToDomain(request.chainId)?.networkId

        return userWalletModel.accountModelsManager.cryptoAccountModels.first(where: { account in
            account.walletModelsManager.walletModels.contains { walletModel in
                let blockchainMatches = blockchainNetworkId.map { walletModel.tokenItem.blockchain.networkId == $0 } ?? true
                let addressMatches = normalizeAddress(walletModel.walletConnectAddress) == requestedAddress
                return blockchainMatches && addressMatches
            }
        })?.id.walletConnectIdentifierString
    }

    private func extractRequestedAddress(from request: Request) -> String? {
        guard let method = WalletConnectMethod(rawValue: request.method) else {
            return nil
        }

        switch method {
        case .sendTransaction, .signTransaction:
            if let params = try? request.params.get([WalletConnectEthTransaction].self) {
                return params.first?.from
            }

            let transaction = try? request.params.get(WalletConnectEthTransaction.self)
            return transaction?.from
        case .personalSign:
            let params = try? request.params.get([String].self)
            guard let params, params.count > 1 else { return nil }
            return params[1]
        case .signTypedData, .signTypedDataV4:
            let params = try? request.params.get([String].self)
            guard let params, !params.isEmpty else { return nil }
            return params[0]
        default:
            return nil
        }
    }

    private func normalizeAddress(_ address: String) -> String {
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        let isEvmAddress = trimmedAddress.hasHexPrefix()
            && trimmedAddress.count == 42
            && trimmedAddress.dropFirst(2).allSatisfy(\.isHexDigit)

        return isEvmAddress ? trimmedAddress.lowercased() : trimmedAddress
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
        cancelModelSubscriptions(for: userWalletId)

        guard let userWalletModel = userWalletRepository.models[userWalletId] else {
            return
        }

        walletModelsCancellables[userWalletId] = AccountsFeatureAwareWalletModelsResolver
            .walletModelsPublisher(for: userWalletModel)
            .map { walletModels in
                WalletModelsUpdate(
                    blockchains: walletModels.compactMap { walletModel -> Blockchain? in
                        guard walletModel.tokenItem.isBlockchain else {
                            return nil
                        }

                        return walletModel.tokenItem.blockchain
                    },
                    hasWalletModels: walletModels.isNotEmpty
                )
            }
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { wcService, update in
                wcService.handleWalletModelsUpdate(blockchains: update.blockchains, for: userWalletId.stringValue)
                wcService.maybeTriggerAccountsMigration(hasWalletModels: update.hasWalletModels)
            }
    }

    func cancelModelSubscriptions(for userWalletId: UserWalletId) {
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

    func maybeTriggerAccountsMigration(hasWalletModels: Bool) {
        guard FeatureProvider.isAvailable(.accounts), hasWalletModels else {
            return
        }

        guard accountsMigrationTask == nil else {
            return
        }

        accountsMigrationTask = Task { [weak self] in
            guard let self else {
                return
            }

            defer {
                self.accountsMigrationTask = nil
            }

            do {
                _ = try await savedSessionToAccountsMigrationService.migrateSavedSessionsToAccounts()
            } catch {
                WCLogger.error("WalletConnect account migration failed", error: error)
                await forceDisconnectAllSessionsAfterMigrationFailure()
            }
        }
    }

    private func forceDisconnectAllSessionsAfterMigrationFailure() async {
        guard let dApps = try? await connectedDAppRepository.getAllDApps(), dApps.isNotEmpty else {
            return
        }

        do {
            try await connectedDAppRepository.delete(dApps: dApps)
        } catch {
            WCLogger.error("Failed to remove WalletConnect sessions after migration failure", error: error)
        }

        await withTaskGroup(of: Void.self) { taskGroup in
            for dApp in dApps {
                taskGroup.addTask {
                    do {
                        try await self.walletKitClient.disconnect(topic: dApp.session.topic)
                    } catch {
                        WCLogger.error(LoggerStrings.failedToDisconnectSession(dApp.session.topic), error: error)
                    }
                }
            }
        }
    }

    private struct WalletModelsUpdate {
        let blockchains: [Blockchain]
        let hasWalletModels: Bool
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
