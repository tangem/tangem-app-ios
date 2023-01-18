//
//  WalletConnectV2Service.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import WalletConnectSwiftV2
import BlockchainSdk

class WalletConnectV2Service {
    @Injected(\.walletConnectSessionsStorage) private var sessionsStorage: WalletConnectSessionsStorage

    private let factory = WalletConnectV2DefaultSocketFactory()
    private let uiDelegate: WalletConnectUIDelegate
    private let messageComposer: WalletConnectV2MessageComposable
    private let pairApi: PairingInteracting
    private let signApi: SignClient
    private let cardModel: CardViewModel

    private var canEstablishNewSessionSubject: CurrentValueSubject<Bool, Never> = .init(true)
    private var bag = Set<AnyCancellable>()

    init(
        with cardModel: CardViewModel,
        uiDelegate: WalletConnectUIDelegate = WalletConnectAlertUIDelegate(),
        messageComposer: WalletConnectV2MessageComposable = WalletConnectV2MessageComposer()
    ) {
        self.cardModel = cardModel
        self.uiDelegate = uiDelegate
        self.messageComposer = messageComposer

        Networking.configure(
            // [REDACTED_TODO_COMMENT]
            projectId: "c0e14e9fac0113e872980f2aae3354de",
            socketFactory: factory,
            socketConnectionType: .automatic
        )
        Pair.configure(metadata: AppMetadata(
            // Not sure that we really need this name, but currently it is hard to recognize what card is connected in dApp
            name: "Tangem \(cardModel.name)",
            description: "NFC crypto wallet",
            url: "tangem.com",
            icons: ["https://user-images.githubusercontent.com/24321494/124071202-72a00900-da58-11eb-935a-dcdab21de52b.png"]
        ))

        pairApi = Pair.instance
        signApi = Sign.instance

        loadSessions(for: cardModel.userWalletId)
        subscribeToMessages()
    }

    func terminateAllSessions() async throws {
        for session in signApi.getSessions() {
            try await signApi.disconnect(topic: session.topic)
        }

        for pairing in pairApi.getPairings() {
            try await pairApi.disconnect(topic: pairing.topic)
        }

        await sessionsStorage.clearStorage()
    }

    private func loadSessions(for userWalletId: Data?) {
        guard let userWalletId else { return }

        Task { [weak self] in
            guard let self else { return }

            AppLog.shared.debug("[WC 2.0] Loading sessions for UserWallet with id: \(userWalletId.hexString)")
            let loadedSessions = await self.sessionsStorage.loadSessions(for: userWalletId.hexString)

            let pairingSessions = self.pairApi.getPairings()
            AppLog.shared.debug("[WC 2.0] Saved pairing sessions in WC storage \(pairingSessions)")

            let sessions = self.signApi.getSessions()
            AppLog.shared.debug("[WC 2.0] Currently active sessions. Restored by framework: \(sessions)")

            AppLog.shared.debug("[WC 2.0] Loaded sessions from internal storage: \(loadedSessions)")

            AppLog.shared.debug("------Stop-------")
        }
    }

    private func subscribeToMessages() {
        signApi.sessionProposalPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessionProposal in
                AppLog.shared.debug("[WC 2.0] Session proposal: \(sessionProposal)")
                self?.validateProposal(sessionProposal)
            }
            .store(in: &bag)

        signApi.sessionSettlePublisher
            .receive(on: DispatchQueue.main)
            .asyncMap { [weak self] session in
                guard
                    let self,
                    let userWalletId = self.cardModel.userWalletId
                else { return }

                AppLog.shared.debug("[WC 2.0] Session established: \(session)")
                let savedSession = WalletConnectV2Utils().createSavedSession(for: session, with: userWalletId.hexString)

                await self.sessionsStorage.save(savedSession)
            }
            .sink()
            .store(in: &bag)
    }

    private func validateProposal(_ proposal: Session.Proposal) {
        let utils = WalletConnectV2Utils()
        AppLog.shared.debug("[WC 2.0] Attemping to approve session proposal: \(proposal)")

        guard utils.isAllChainsSupported(in: proposal.requiredNamespaces) else {
            let unsupportedBlockchains = utils.extractUnsupportedBlockchainNames(from: proposal.requiredNamespaces)
            displayErrorUI(.unsupportedBlockchains(unsupportedBlockchains))
            sessionRejected(with: proposal)
            return
        }

        do {
            let sessionNamespaces = try WalletConnectV2Utils().createSessionNamespaces(
                from: proposal.requiredNamespaces,
                for: cardModel.wallets
            )
            displaySessionConnectionUI(for: proposal, namespaces: sessionNamespaces)
        } catch let error as WalletConnectV2Error {
            displayErrorUI(error)
        } catch {
            AppLog.shared.error("[WC 2.0] \(error)")
        }
    }

    private func displaySessionConnectionUI(for proposal: Session.Proposal, namespaces: [String: SessionNamespace]) {
        AppLog.shared.debug("[WC 2.0] Did receive session proposal")
        let blockchains = WalletConnectV2Utils().getBlockchainNamesFromNamespaces(namespaces)
        let message = messageComposer.makeMessage(for: proposal, targetBlockchains: blockchains)
        uiDelegate.showScreen(with: WalletConnectUIRequest(
            event: .establishSession,
            message: message,
            approveAction: { [weak self] in
                self?.sessionAccepted(with: proposal.id, namespaces: namespaces)
            },
            rejectAction: { [weak self] in
                self?.sessionRejected(with: proposal)
            }
        ))
    }

    private func displayErrorUI(_ error: WalletConnectV2Error) {
        let message = messageComposer.makeErrorMessage(error)
        uiDelegate.showScreen(with: WalletConnectUIRequest(
            event: .error,
            message: message,
            approveAction: {}
        ))
    }

    // MARK: - Session manipulation

    private func sessionAccepted(with id: String, namespaces: [String: SessionNamespace]) {
        runTask { [weak self] in
            guard let self else { return }

            do {
                AppLog.shared.debug("[WC 2.0] Namespaces to approve for session connection: \(namespaces)")
                try await self.signApi.approve(proposalId: id, namespaces: namespaces)
            } catch let error as WalletConnectV2Error {
                self.displayErrorUI(error)
            } catch {
                let mappedError = WalletConnectV2ErrorMappingUtils().mapWCv2Error(error)
                self.displayErrorUI(mappedError)
                AppLog.shared.error("[WC 2.0] Failed to approve Session with error: \(error)")
            }
        }
    }

    private func sessionRejected(with proposal: Session.Proposal) {
        runTask { [weak self] in
            do {
                try await self?.signApi.reject(proposalId: proposal.id, reason: .userRejectedChains)
                AppLog.shared.debug("[WC 2.0] User reject WC connection")
            } catch {
                AppLog.shared.error("[WC 2.0] Failed to reject WC connection with error: \(error)")
            }
        }
    }
}

extension WalletConnectV2Service: WalletConnectURLHandler {
    func canHandle(url: String) -> Bool {
        return WalletConnectURI(string: url) != nil
    }

    func handle(url: URL) -> Bool {
        return handle(url: url.absoluteString)
    }

    func handle(url: String) -> Bool {
        guard let uri = WalletConnectURI(string: url) else {
            return false
        }

        canEstablishNewSessionSubject.send(false)
        pairClient(with: uri)
        return true
    }

    private func pairClient(with uri: WalletConnectURI) {
        AppLog.shared.debug("[WC 2.0] Trying to pair client: \(uri)")
        Task {
            do {
                try await pairApi.pair(uri: uri)
                AppLog.shared.debug("[WC 2.0] Established pair for \(uri)")
            } catch {
                AppLog.shared.error("[WC 2.0] Failed to connect to \(uri) with error: \(error)")
            }
            canEstablishNewSessionSubject.send(true)
        }
    }
}

extension WalletConnectV2Service {
    var canEstablishNewSessionPublisher: AnyPublisher<Bool, Never> {
        canEstablishNewSessionSubject
            .eraseToAnyPublisher()
    }

    var sessionsPublisher: AnyPublisher<[WalletConnectSession], Never> {
        Just([])
            .eraseToAnyPublisher()
    }

    var newSessions: AsyncStream<[WalletConnectSavedSession]> {
        get async {
            await sessionsStorage.sessions
        }
    }

    func disconnectSession(with id: Int) async {
        guard let session = await sessionsStorage.session(with: id) else { return }

        do {
            try await signApi.disconnect(topic: session.topic)
            await sessionsStorage.remove(session)
        } catch {
            let internalError = WalletConnectV2ErrorMappingUtils().mapWCv2Error(error)
            if case .sessionForTopicNotFound = internalError {
                await sessionsStorage.remove(session)
                return
            }
            AppLog.shared.error("[WC 2.0] Failed to disconnect session with topic: \(session.topic) with error: \(error)")
        }
    }
}
