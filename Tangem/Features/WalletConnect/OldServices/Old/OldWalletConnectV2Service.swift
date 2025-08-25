//
//  WalletConnectV2Service.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import ReownWalletKit
import BlockchainSdk
import TangemFoundation
import TangemLocalization
import TangemUI

protocol OldWalletConnectUserWalletInfoProvider: AnyObject {
    var userWalletId: UserWalletId { get }
    var signer: TangemSigner { get }
    var wcWalletModelProvider: WalletConnectWalletModelProvider { get }
}

final class OldWalletConnectV2Service {
    @Injected(\.walletConnectSessionsStorage) private var sessionsStorage: WalletConnectSessionsStorage
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private let walletKitClient: WalletKitClient
    private let uiDelegate: WalletConnectUIDelegate
    private let messageComposer: WalletConnectV2MessageComposable
    private let wcHandlersService: WalletConnectV2HandlersServicing

    private var canEstablishNewSessionSubject: CurrentValueSubject<Bool, Never> = .init(true)
    private var sessionSubscriptions = Set<AnyCancellable>()
    private var messagesSubscriptions = Set<AnyCancellable>()

    var canEstablishNewSessionPublisher: AnyPublisher<Bool, Never> {
        canEstablishNewSessionSubject
            .eraseToAnyPublisher()
    }

    var newSessions: AsyncStream<[WalletConnectSavedSession]> {
        get async {
            await sessionsStorage.sessions
        }
    }

    private weak var infoProvider: OldWalletConnectUserWalletInfoProvider?

    init(
        walletKitClient: WalletKitClient,
        uiDelegate: WalletConnectUIDelegate,
        messageComposer: WalletConnectV2MessageComposable,
        wcHandlersService: WalletConnectV2HandlersServicing
    ) {
        self.walletKitClient = walletKitClient
        self.uiDelegate = uiDelegate
        self.messageComposer = messageComposer
        self.wcHandlersService = wcHandlersService

        guard !FeatureProvider.isAvailable(.walletConnectUI) else { return }

        setupSessionSubscriptions()
        setupMessagesSubscriptions()
    }

    func initialize(with infoProvider: OldWalletConnectUserWalletInfoProvider) {
        self.infoProvider = infoProvider
        runTask { [weak self] in
            await self?.sessionsStorage.loadSessions()
        }
    }

    func openSession(with uri: WalletConnectV2URI, source: Analytics.WalletConnectSessionSource) {
        canEstablishNewSessionSubject.send(false)
        runTask(withTimeout: 20) { [weak self] in
            await self?.pairClient(with: uri, source: source)
        } onTimeout: { [weak self] in
            self?.displayErrorUI(WalletConnectV2Error.sessionConnectionTimeout)
            Analytics.log(.walletConnectSessionFailed)
            self?.canEstablishNewSessionSubject.send(true)
        }
    }

    func disconnectSession(with id: Int) async {
        guard let session = await sessionsStorage.session(with: id) else {
            WCLogger.error(error: "Failed to find session with id: \(id). Attempt to disconnect session failed")
            return
        }

        do {
            WCLogger.info("Attempt to disconnect session with topic: \(session.topic)")
            try await walletKitClient.disconnect(topic: session.topic)

            Analytics.log(
                event: .walletConnectDAppDisconnected,
                params: [
                    .walletConnectDAppName: session.sessionInfo.dAppInfo.name,
                    .walletConnectDAppUrl: session.sessionInfo.dAppInfo.url,
                ]
            )

            WCLogger.info("Session with topic: \(session.topic) was disconnected from SignAPI. Removing from storage")
            await sessionsStorage.remove(session)
        } catch {
            let internalError = WalletConnectV2ErrorMappingUtils().mapWCv2Error(error)
            switch internalError {
            case .sessionForTopicNotFound, .symmetricKeyForTopicNotFound:
                WCLogger.error("Failed to remove session with \(session.topic) from SignAPI. Removing anyway from storage", error: internalError)
                await sessionsStorage.remove(session)
                return
            default:
                break
            }
            WCLogger.error("Failed to disconnect session with topic: \(session.topic)", error: error)
        }
    }

    func disconnectAllSessionsForUserWallet(with userWalletId: String) {
        runTask { [weak self, walletKitClient] in
            guard let self else { return }

            let removedSessions = await sessionsStorage.removeSessions(for: userWalletId)
            for session in removedSessions {
                do {
                    try await walletKitClient.disconnect(topic: session.topic)
                } catch {
                    WCLogger.error("Failed to disconnect session while disconnecting all sessions for user wallet with id: \(userWalletId)", error: error)
                }
            }
        }
    }

    private func pairClient(with url: WalletConnectURI, source: Analytics.WalletConnectSessionSource) async {
        WCLogger.info("Trying to pair client: \(url)")
        Analytics.log(event: .walletConnectSessionInitiated, params: [Analytics.ParameterKey.source: source.rawValue])

        do {
            try await walletKitClient.pair(uri: url)
            try Task.checkCancellation()
            WCLogger.info("Established pair for \(url)")
            DispatchQueue.main.async {
                Toast(view: SuccessToast(text: Localization.walletConnectToastAwaitingSessionProposal))
                    .present(
                        layout: .top(padding: 20),
                        type: .temporary()
                    )
            }
        } catch {
            displayErrorUI(WalletConnectV2Error.pairClientError(error.localizedDescription))
            WCLogger.error("Failed to connect to \(url)", error: error)
            Analytics.log(.walletConnectSessionFailed)

            // Hack to delete the topic from the user default storage inside the WC 2.0 SDK
            await disconnect(topic: url.topic)
        }
        canEstablishNewSessionSubject.send(true)
    }

    private func disconnect(topic: String) async {
        do {
            try await walletKitClient.disconnect(topic: topic)
            WCLogger.info("Success disconnect/delete topic \(topic)")
        } catch {
            WCLogger.error("Failed to disconnect/delete topic \(topic)", error: error)
        }
    }

    // MARK: - Subscriptions

    private func setupSessionSubscriptions() {
        walletKitClient
            .sessionProposalPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessionProposal, context in
                WCLogger.info("Session proposal: \(sessionProposal) with verify context: \(String(describing: context))")
                Analytics.debugLog(eventInfo: Analytics.WalletConnectDebugEvent.receiveSessionProposal(name: sessionProposal.proposer.name, dAppURL: sessionProposal.proposer.url))
                self?.validateProposal(sessionProposal)
            }
            .store(in: &sessionSubscriptions)

        walletKitClient
            .sessionSettlePublisher
            .receive(on: DispatchQueue.main)
            .asyncMap { [weak self] session in
                guard let self else { return }

                if infoProvider == nil {
                    WCLogger.info("Info provider is not setup. Saved session will miss some info")
                }

                WCLogger.info("Session established: \(session)")

                let savedSession = session.mapToWCSavedSession(with: infoProvider?.userWalletId.stringValue ?? "")

                canEstablishNewSessionSubject.send(true)

                WCLogger.info("Saving session with topic: \(savedSession.topic).\ndApp url: \(savedSession.sessionInfo.dAppInfo.url)")
                await sessionsStorage.save(savedSession)
            }
            .sink()
            .store(in: &sessionSubscriptions)

        walletKitClient
            .sessionDeletePublisher
            .receive(on: DispatchQueue.main)
            .asyncMap { [weak self] topic, reason in
                guard let self else { return }

                WCLogger.info("Receive Delete session message with topic: \(topic). Delete reason: \(reason)")

                guard let session = await sessionsStorage.session(with: topic) else {
                    WCLogger.info("Receive Delete session message with topic: \(topic). Delete reason: \(reason). But session not found.")
                    return
                }

                Analytics.log(
                    event: .walletConnectDAppDisconnected,
                    params: [
                        .walletConnectDAppName: session.sessionInfo.dAppInfo.name,
                        .walletConnectDAppUrl: session.sessionInfo.dAppInfo.url,
                    ]
                )

                WCLogger.info("Session with topic (\(topic)) was found. Deleting session from storage...")
                await sessionsStorage.remove(session)
            }
            .sink()
            .store(in: &sessionSubscriptions)
    }

    private func setupMessagesSubscriptions() {
        walletKitClient
            .sessionRequestPublisher
            .receive(on: DispatchQueue.main)
            .asyncMap { [weak self] request, context in
                guard let self else { return }

                Analytics.debugLog(eventInfo: Analytics.WalletConnectDebugEvent.receiveRequestFromDApp(method: request.method))
                WCLogger.info("Receive message request: \(request) with verify context: \(String(describing: context))")
                await handle(request)
            }
            .sink()
            .store(in: &messagesSubscriptions)
    }

    private func validateProposal(_ proposal: Session.Proposal) {
        let utils = OldWalletConnectV2Utils()
        WCLogger.info("Attemping to approve session proposal: \(proposal)")

        guard let infoProvider else {
            displayErrorUI(.missingActiveUserWalletModel)
            sessionRejected(with: proposal)
            return
        }

        guard DApps().isSupported(proposal.proposer.url) else {
            displayErrorUI(.unsupportedDApp)
            sessionRejected(with: proposal)
            return
        }

        guard utils.allChainsSupported(in: proposal.requiredNamespaces) else {
            let unsupportedBlockchains = utils.extractUnsupportedBlockchainNames(from: proposal.requiredNamespaces)
            displayErrorUI(.unsupportedBlockchains(unsupportedBlockchains))
            sessionRejected(with: proposal)
            return
        }

        do {
            let sessionNamespaces = try utils.createSessionNamespaces(
                proposal: proposal,
                walletModelProvider: infoProvider.wcWalletModelProvider
            )
            displaySessionConnectionUI(for: proposal, namespaces: sessionNamespaces)
            logDAppConnectionRequested(namespaces: sessionNamespaces)
        } catch let error as WalletConnectV2Error {
            displayErrorUI(error)
        } catch {
            WCLogger.error(error: error)
            displayErrorUI(.unknown(error.localizedDescription))
        }
        canEstablishNewSessionSubject.send(true)
    }

    // MARK: - UI Related

    private func displaySessionConnectionUI(for proposal: Session.Proposal, namespaces: [String: SessionNamespace]) {
        WCLogger.info("Did receive session proposal")

        guard let infoProvider else {
            displayErrorUI(.missingActiveUserWalletModel)
            sessionRejected(with: proposal)
            return
        }

        let blockchains = OldWalletConnectV2Utils().getBlockchainNamesFromNamespaces(namespaces, walletModelProvider: infoProvider.wcWalletModelProvider)
        let message = messageComposer.makeMessage(for: proposal, targetBlockchains: blockchains)
        uiDelegate.showScreen(with: WalletConnectUIRequest(
            event: .establishSession,
            message: message,
            approveAction: { [weak self] in
                self?.sessionAccepted(with: proposal, namespaces: namespaces, blockchainNames: blockchains)
            },
            rejectAction: { [weak self] in
                self?.sessionRejected(with: proposal)
            }
        ))
    }

    private func displayErrorUI(_ error: WalletConnectV2Error) {
        Analytics.debugLog(eventInfo: Analytics.WalletConnectDebugEvent.errorShownToTheUser(error: error.localizedDescription))
        uiDelegate.showScreen(with: WalletConnectUIRequest(
            event: .error,
            message: error.localizedDescription,
            approveAction: {}
        ))
    }

    // MARK: - Session manipulation

    private func sessionAccepted(with proposal: Session.Proposal, namespaces: [String: SessionNamespace], blockchainNames: [String]) {
        runTask(in: self) { strongSelf in
            do {
                WCLogger.info("Namespaces to approve for session connection: \(namespaces)")
                _ = try await strongSelf.walletKitClient.approve(proposalId: proposal.id, namespaces: namespaces)
                Self.logDAppConnected(proposal: proposal, blockchainNames: blockchainNames)
            } catch let error as WalletConnectV2Error {
                strongSelf.displayErrorUI(error)
                Self.logDAppConnectionFailed(proposal: proposal, blockchainNames: blockchainNames)
            } catch {
                let mappedError = WalletConnectV2ErrorMappingUtils().mapWCv2Error(error)
                strongSelf.displayErrorUI(mappedError)
                WCLogger.error("Failed to approve Session", error: error)
                Self.logDAppConnectionFailed(proposal: proposal, blockchainNames: blockchainNames)
            }
        }
    }

    private func sessionRejected(with proposal: Session.Proposal) {
        runTask(in: self) { strongSelf in
            do {
                try await strongSelf.walletKitClient.rejectSession(proposalId: proposal.id, reason: .userRejected)
                WCLogger.info("User reject WC connection")
            } catch {
                WCLogger.error("Failed to reject WC connection", error: error)
            }
            strongSelf.canEstablishNewSessionSubject.send(true)
        }
    }

    // MARK: - Message handling

    private func handle(_ request: Request) async {
        func respond(with error: WalletConnectV2Error, session: WalletConnectSavedSession?) async {
            WCLogger.error(error: error)

            logSignatureRequestEvent(
                .walletConnectSignatureRequestFailed,
                request: request,
                session: session,
                error: error
            )

            try? await walletKitClient.respond(
                topic: request.topic,
                requestId: request.id,
                response: .error(.init(code: 0, message: error.localizedDescription))
            )
        }

        let session = await sessionsStorage.session(with: request.topic)

        logSignatureRequestEvent(
            .walletConnectSignatureRequestReceived,
            request: request,
            session: session,
            error: nil
        )

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
            try await walletKitClient.respond(topic: session.topic, requestId: request.id, response: result)

            let event: Analytics.Event
            let signatureHandlingError: WalletConnectV2Error?

            switch result {
            case .response:
                event = Analytics.Event.walletConnectSignatureRequestHandled
                signatureHandlingError = nil
            case .error(let error):
                event = Analytics.Event.walletConnectSignatureRequestFailed
                signatureHandlingError = WalletConnectV2Error.unknown(error.localizedDescription)
            }

            logSignatureRequestEvent(event, request: request, session: session, error: signatureHandlingError)

        } catch let error as WalletConnectV2Error {
            if case .unsupportedWCMethod = error {} else {
                displayErrorUI(error)
            }
            await respond(with: error, session: session)
        } catch {
            let wcError: WalletConnectV2Error = .unknown(error.localizedDescription)
            displayErrorUI(wcError)
            await respond(with: wcError, session: session)
        }
    }
}

// MARK: - Analytics related methods

extension OldWalletConnectV2Service {
    private func logSignatureRequestEvent(
        _ event: Analytics.Event,
        request: Request,
        session: WalletConnectSavedSession?,
        error: WalletConnectV2Error?
    ) {
        var params: [Analytics.ParameterKey: String] = [:]

        if let session {
            params[.walletConnectDAppName] = session.sessionInfo.dAppInfo.name
            params[.walletConnectDAppUrl] = session.sessionInfo.dAppInfo.url
        }

        if let blockchainCurrencySymbol = OldWalletConnectV2Utils().createBlockchain(for: request.chainId)?.currencySymbol {
            params[.walletConnectBlockchain] = blockchainCurrencySymbol
        }

        params[.methodName] = request.method

        if let error {
            params[.validation] = Analytics.ParameterValue.fail.rawValue
            params[.errorCode] = "\(error.code)"
            let errorDescription: String
            if case .unknown(let externalErrorMessage) = error {
                errorDescription = externalErrorMessage
            } else {
                errorDescription = error.errorDescription ?? "No error description"
            }
            params[.errorDescription] = errorDescription
        } else {
            params[.validation] = Analytics.ParameterValue.success.rawValue
            params[.errorCode] = "0"
        }

        Analytics.log(event: event, params: params)
    }

    private func logDAppConnectionRequested(namespaces: [String: SessionNamespace]) {
        guard let infoProvider else { return }

        let blockchainNames = OldWalletConnectV2Utils()
            .getBlockchainNamesFromNamespaces(namespaces, walletModelProvider: infoProvider.wcWalletModelProvider)
            .joined(separator: ",")

        let event = Analytics.Event.walletConnectDAppSessionProposalReceived
        let params: [Analytics.ParameterKey: String] = [
            .networks: blockchainNames,
        ]

        Analytics.log(event: event, params: params)
    }

    private static func logDAppConnected(proposal: Session.Proposal, blockchainNames: [String]) {
        logDAppConnectionStatusEvent(.walletConnectDAppConnected, proposal: proposal, blockchainNames: blockchainNames)
    }

    private static func logDAppConnectionFailed(proposal: Session.Proposal, blockchainNames: [String]) {
        logDAppConnectionStatusEvent(.walletConnectDAppConnectionFailed, proposal: proposal, blockchainNames: blockchainNames)
    }

    private static func logDAppConnectionStatusEvent(_ event: Analytics.Event, proposal: Session.Proposal, blockchainNames: [String]) {
        let params: [Analytics.ParameterKey: String] = [
            .walletConnectDAppName: proposal.proposer.name,
            .walletConnectDAppUrl: proposal.proposer.url,
            .walletConnectBlockchain: blockchainNames.joined(separator: ","),
        ]

        Analytics.log(event: event, params: params)
    }
}

public typealias WalletConnectV2URI = WalletConnectURI

private struct DApps {
    private let unsupportedList: [String] = [
        "dydx.exchange",
        "pro.apex.exchange",
        "sandbox.game",
        "app.paradex.trade",
    ]

    func isSupported(_ dAppURL: String) -> Bool {
        for dApp in unsupportedList {
            if dAppURL.contains(dApp) {
                return false
            }
        }

        return true
    }
}
