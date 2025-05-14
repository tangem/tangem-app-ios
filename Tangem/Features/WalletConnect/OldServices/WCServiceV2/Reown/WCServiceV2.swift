//
//  WCServiceV2.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemFoundation
import ReownWalletKit
import TangemLocalization
import TangemUI

final class WCServiceV2 {
    // MARK: - Dependencies

    @Injected(\.walletConnectSessionsStorage) private var sessionsStorage: WalletConnectSessionsStorage
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.keysManager) private var keysManager: KeysManager
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter

    // MARK: - Public properties

    var canEstablishNewSessionPublisher: AnyPublisher<Bool, Never> {
        canEstablishNewSessionSubject.eraseToAnyPublisher()
    }

    var newSessions: AsyncStream<[WalletConnectSavedSession]> {
        get async {
            await sessionsStorage.sessions
        }
    }

    var errorsPublisher: AnyPublisher<(error: WalletConnectV2Error, dAppName: String), Never> {
        errorsSubject.eraseToAnyPublisher()
    }

    // MARK: - Private properties

    private var selectedWalletId: String?
    private var currentConnectionProposal: Session.Proposal?

    // MARK: - Subjects

    private let canEstablishNewSessionSubject: CurrentValueSubject<Bool, Never> = .init(true)
    private let dappInfoLoadingSubject: CurrentValueSubject<Bool, Never> = .init(false)
    private let proposalSubject: CurrentValueSubject<Session.Proposal?, Never> = .init(nil)
    private let selectedWalletIdSubject: CurrentValueSubject<String?, Never> = .init(nil)
    private let selectedNetworksToConnectSubject: PassthroughSubject<[BlockchainNetwork], Never> = .init()
    private let connectionRequestSubject: CurrentValueSubject<WCConnectionRequestModel?, Never> = .init(nil)
    private let errorsSubject = PassthroughSubject<(error: WalletConnectV2Error, dAppName: String), Never>()
    private var bag = Set<AnyCancellable>()

    private let utils = WCUtils()
    private let factory = WalletConnectV2DefaultSocketFactory()
    private let wcHandlersService: WalletConnectV2HandlersServicing

    init(wcHandlersService: WalletConnectV2HandlersServicing) {
        self.wcHandlersService = wcHandlersService

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

// MARK: - Update session data

extension WCServiceV2 {
    func updateConnectionData(userWalletId: String) {
        guard userWalletId != selectedWalletId else { return }

        selectedWalletIdSubject.send(userWalletId)
    }

    func updateConnectionData(networks: [BlockchainNetwork]) {
        selectedNetworksToConnectSubject.send(networks)
    }
}

// MARK: - Bind

private extension WCServiceV2 {
    func bind() {
        subscribeToSelectedWalletId()
        subscribeToSelectedNetwork()
        subscribeToWCPublishers()
    }

    func subscribeToWCPublishers() {
        WalletKit.instance.sessionProposalPublisher
            .sink { [weak self] sessionProposal, context in
                WCLogger.info(LoggerStrings.sessionProposal(sessionProposal, context))
                Analytics.debugLog(eventInfo: Analytics.WalletConnectDebugEvent.receiveSessionProposal(name: sessionProposal.proposer.name, dAppURL: sessionProposal.proposer.url))

                guard let selectedWCModelProvider = self?.userWalletRepository.models.first(where: { $0.userWalletId.stringValue == self?.selectedWalletId }
                )?.wcWalletModelProvider else { return }

                self?.validateProposal(sessionProposal, with: selectedWCModelProvider)
                self?.currentConnectionProposal = sessionProposal
            }
            .store(in: &bag)

        WalletKit.instance.sessionSettlePublisher
            .asyncMap { [weak self] session in
                guard let self else { return }

                if selectedWalletId == nil {
                    WCLogger.info(LoggerStrings.noSelectedWallet)
                }

                WCLogger.info(LoggerStrings.sessionEstablished(session))

                let savedSession = session.mapToWCSavedSession(with: selectedWalletId ?? "")

                canEstablishNewSessionSubject.send(true)

                WCLogger.info(LoggerStrings.savedSession(savedSession.topic, savedSession.sessionInfo.dAppInfo.url))
                await sessionsStorage.save(savedSession)
            }
            .sink()
            .store(in: &bag)

        WalletKit.instance.sessionDeletePublisher
            .receive(on: DispatchQueue.main)
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

    func subscribeToSelectedNetwork() {
        selectedNetworksToConnectSubject
            .dropFirst()
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { wcService, selectedNetworks in
                guard
                    let currentConnectionProposal = wcService.currentConnectionProposal,
                    let wcModelProvider = wcService.userWalletRepository.models.first(where: { $0.userWalletId.stringValue == wcService.selectedWalletId }
                    )?.wcWalletModelProvider
                else {
                    return
                }

                wcService.validateProposal(
                    currentConnectionProposal,
                    with: wcModelProvider,
                    selectedNetworks: selectedNetworks
                )
            }
            .store(in: &bag)
    }

    func subscribeToSelectedWalletId() {
        selectedWalletIdSubject
            .dropFirst()
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { wcService, updatedId in
                guard
                    let currentConnectionProposal = wcService.currentConnectionProposal,
                    let wcModelProvider = wcService.userWalletRepository.models.first(where: { $0.userWalletId.stringValue == updatedId })?.wcWalletModelProvider
                else {
                    return
                }
                wcService.selectedWalletId = updatedId
                wcService.validateProposal(currentConnectionProposal, with: wcModelProvider)
            }
            .store(in: &bag)
    }
}

// MARK: - Validate proposal

private extension WCServiceV2 {
    func validateProposal(
        _ proposal: Session.Proposal,
        with wcModelProvider: some WalletConnectWalletModelProvider,
        selectedNetworks: [BlockchainNetwork] = []
    ) {
        WCLogger.info(LoggerStrings.attemptingToApproveSession(proposal))

        guard let selectedWalletId else { return }

        guard DApps.isSupported(proposal.proposer.url) else {
            errorsSubject.send((.unsupportedDApp, proposal.proposer.name))
            reject(with: proposal)
            return
        }

        guard utils.allChainsSupported(in: proposal.requiredNamespaces) else {
            let unsupportedBlockchainNames = utils.extractUnsupportedBlockchainNames(from: proposal.requiredNamespaces)
            errorsSubject.send((.unsupportedBlockchains(unsupportedBlockchainNames), proposal.proposer.name))
            reject(with: proposal)
            return
        }

        do {
            let (sessionsNamespaces, requestData) = try utils.createSessionRequest(
                proposal: proposal,
                selectedWalletModelProvider: wcModelProvider,
                selectedUserWalletModelId: selectedWalletId,
                selectedOptionalNetworks: selectedNetworks
            )

            proposalSubject.send(proposal)

            connectionRequestSubject.send(
                .init(
                    userWalletModelId: selectedWalletId,
                    requestData: requestData,
                    sessionNamespaces: sessionsNamespaces,
                    connect: {
                        try await self.accept(
                            with: proposal.id,
                            dappName: proposal.proposer.name,
                            namespaces: sessionsNamespaces
                        )
                    },
                    cancel: { self.reject(with: proposal) }
                )
            )

            //            log request
        } catch let error as WalletConnectV2Error {
            errorsSubject.send((error, proposal.proposer.name))
        } catch {
            WCLogger.error(error: error)
            errorsSubject.send((.unknown(error.localizedDescription), proposal.proposer.name))
        }
        canEstablishNewSessionSubject.send(true)
        dappInfoLoadingSubject.send(false)
    }
}

// MARK: - Connect

extension WCServiceV2 {
    func openSession(with uri: WalletConnectV2URI, source: Analytics.WalletConnectSessionSource) {
        // [REDACTED_TODO_COMMENT]

        canEstablishNewSessionSubject.send(false)
        dappInfoLoadingSubject.send(true)

        Task { @MainActor in
            floatingSheetPresenter.enqueue(
                sheet: WCConnectionSheetViewModel(
                    requestPublisher: connectionRequestSubject.eraseToAnyPublisher(),
                    dappInfoLoadingPublisher: dappInfoLoadingSubject.eraseToAnyPublisher(),
                    proposalPublisher: proposalSubject.eraseToAnyPublisher()
                )
            )
        }

        runTask(withTimeout: 20) { [weak self] in
            await self?.pairClient(with: uri, source: source)
        } onTimeout: { [weak self] in
            self?.dismissFloatingSheetWithToast(error: WalletConnectV2Error.sessionConnectionTimeout)

            self?.canEstablishNewSessionSubject.send(true)
            self?.dappInfoLoadingSubject.send(false)
        }
    }

    private func pairClient(with url: WalletConnectURI, source: Analytics.WalletConnectSessionSource) async {
        WCLogger.info(LoggerStrings.tryingToPairClient(url))
        Analytics.log(event: .walletConnectSessionInitiated, params: [Analytics.ParameterKey.source: source.rawValue])

        do {
            try await WalletKit.instance.pair(uri: url)

            try Task.checkCancellation()

            WCLogger.info(LoggerStrings.establishedPair(url))

            selectedWalletId = userWalletRepository.selectedUserWalletId?.stringValue
        } catch {
            dismissFloatingSheetWithToast(error: error)

            WCLogger.error(LoggerStrings.failedToConnect(url), error: error)
            Analytics.log(.walletConnectSessionFailed)

            // Hack to delete the topic from the user default storage inside the WC 2.0 SDK
            await disconnect(topic: url.topic)
            dappInfoLoadingSubject.send(false)
        }
        canEstablishNewSessionSubject.send(true)
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

// MARK: - Session Actions

private extension WCServiceV2 {
    func accept(with proposalId: String, dappName: String, namespaces: [String: SessionNamespace]) async throws {
        WCLogger.info(LoggerStrings.namespacesToApprove(namespaces))
        _ = try await WalletKit.instance.approve(proposalId: proposalId, namespaces: namespaces)
        makeSuccessToast(with: "\(dappName) has been connected")
    }

    func reject(with proposal: Session.Proposal) {
        runTask(in: self) { strongSelf in
            do {
                try await WalletKit.instance.rejectSession(proposalId: proposal.id, reason: .userRejected)
                WCLogger.info(LoggerStrings.userRejectWC)
            } catch {
                WCLogger.error(LoggerStrings.failedToRejectWC, error: error)
            }
            strongSelf.canEstablishNewSessionSubject.send(true)
        }
    }
}

// MARK: - Handlers

private extension WCServiceV2 {
    func handle(_ request: Request) async {
        func respond(with error: WalletConnectV2Error, session: WalletConnectSavedSession?) async {
            WCLogger.error(error: error)

//            logSignatureRequestEvent(
//                .walletConnectSignatureRequestFailed,
//                request: request,
//                session: session,
//                error: error
//            )

            try? await WalletKit.instance.respond(
                topic: request.topic,
                requestId: request.id,
                response: .error(.init(code: 0, message: error.localizedDescription))
            )
        }

        let session = await sessionsStorage.session(with: request.topic)

//        logSignatureRequestEvent(
//            .walletConnectSignatureRequestReceived,
//            request: request,
//            session: session,
//            error: nil
//        )

        let logSuffix = " for request: \(request.id)"
        let utils = OldWalletConnectV2Utils()

        guard let session else {
            WCLogger.warning("Failed to find session in storage \(logSuffix)")
            await respond(with: .wrongCardSelected, session: nil)
            return
        }

        guard let targetBlockchain = utils.createBlockchain(for: request.chainId) else {
            WCLogger.warning("Failed to create blockchain \(logSuffix)")
            await respond(with: .missingBlockchains([request.chainId.absoluteString]), session: session)
            return
        }

        if userWalletRepository.models.isEmpty {
            WCLogger.warning("User wallet repository is locked")
            await respond(with: .userWalletRepositoryIsLocked, session: session)
            return
        }

        guard let userWallet = userWalletRepository.models.first(where: { $0.userWalletId.stringValue == session.userWalletId }) else {
            WCLogger.warning("Failed to find target user wallet")
            await respond(with: .missingActiveUserWalletModel, session: session)
            return
        }

        if userWallet.isUserWalletLocked {
            WCLogger.warning("Attempt to handle message with locked user wallet")
            await respond(with: .userWalletIsLocked, session: session)
            return
        }

        do {
            let result = try await wcHandlersService.handle(
                request,
                from: session.sessionInfo.dAppInfo,
                blockchainId: targetBlockchain.id,
                signer: userWallet.signer,
                walletModelProvider: CommonWalletConnectWalletModelProvider(walletModelsManager: userWallet.walletModelsManager)
            )

            WCLogger.info("Receive result from user \(result) for \(logSuffix)")
            try await WalletKit.instance.respond(topic: session.topic, requestId: request.id, response: result)

//            logSignatureRequestEvent(
//                .walletConnectSignatureRequestHandled,
//                request: request,
//                session: session,
//                error: nil
//            )

        } catch let error as WalletConnectV2Error {
            if case .unsupportedWCMethod = error {} else {
                errorsSubject.send((error, session.sessionInfo.dAppInfo.name))
            }
            await respond(with: error, session: session)
        } catch {
            let wcError = WalletConnectV2Error.unknown(error.localizedDescription)
            errorsSubject.send((wcError, session.sessionInfo.dAppInfo.name))
            await respond(with: wcError, session: session)
        }
    }
}

// MARK: - Toast

private extension WCServiceV2 {
    func dismissFloatingSheetWithToast(error: Error) {
        makeWarningToast(with: error.localizedDescription)

        Task { @MainActor in
            self.floatingSheetPresenter.removeActiveSheet()
        }
    }

    func makeSuccessToast(with message: String) {
        DispatchQueue.main.async {
            Toast(view: SuccessToast(text: message))
                .present(layout: .top(padding: 20), type: .temporary())
        }
    }

    func makeWarningToast(with message: String) {
        DispatchQueue.main.async {
            Toast(view: WarningToast(text: message))
                .present(layout: .top(padding: 20), type: .temporary(interval: 3))
        }
    }
}

// MARK: - Unsupported dApps

private enum DApps {
    private static let unsupportedList: [String] = [
        "dydx.exchange",
        "pro.apex.exchange",
        "sandbox.game",
        "app.paradex.trade",
    ]

    static func isSupported(_ dAppURL: String) -> Bool {
        for dApp in unsupportedList {
            if dAppURL.contains(dApp) {
                return false
            }
        }

        return true
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
