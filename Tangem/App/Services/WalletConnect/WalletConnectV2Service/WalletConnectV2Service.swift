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
    @Injected(\.walletConnectStorage) private var storage: WalletConnectStorage
    private var _canEstablishNewSessionPublisher: CurrentValueSubject<Bool, Never> = .init(true)

    private let uiDelegate: WalletConnectUIDelegate
    private let messageComposer: WalletConnectV2MessageComposable
    private let pairApi: PairingInteracting
    private let signApi: SignClient

    private let factory = WalletConnectV2DefaultSocketFactory()
    private let cardModel: CardViewModel

    private var bag = Set<AnyCancellable>()

    init(
        with cardModel: CardViewModel,
        uiDelegate: WalletConnectUIDelegate = WalletConnectAlertUIDelegate(),
        messageComposer: WalletConnectV2MessageComposable = WalletConnectV2MessageComposer()
    ) {
        self.cardModel = cardModel
        self.uiDelegate = uiDelegate
        self.messageComposer = messageComposer

        Networking.configure(projectId: "c0e14e9fac0113e872980f2aae3354de", socketFactory: factory, socketConnectionType: .automatic)
        Pair.configure(metadata: AppMetadata(name: "Tangem", description: "NFC crypto wallet", url: "tangem.com", icons: ["https://user-images.githubusercontent.com/24321494/124071202-72a00900-da58-11eb-935a-dcdab21de52b.png"]))
        pairApi = Pair.instance
        signApi = Sign.instance

        loadSessions(for: cardModel.userWalletId)
        subscribeToMessages()
    }

    func terminateAllSessions() async throws {
        for session in self.signApi.getSessions() {
            try await self.signApi.disconnect(topic: session.topic)
        }

        for pairing in self.pairApi.getPairings() {
            try await self.pairApi.disconnect(topic: pairing.topic)
        }

        await storage.clearStorage()
    }

    private func loadSessions(for userWalletId: Data?) {
        guard let userWalletId else { return }

        Task { [weak self] in
            guard let self else { return }

//            try await self.disconnectAllSessions()

            await self.storage.loadSessions(for: userWalletId.hexString)

            let pairingSessions = self.pairApi.getPairings()
            AppLog.shared.debug(pairingSessions)

            let sessions = self.signApi.getSessions()
            AppLog.shared.debug(sessions)
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
                let savedSession = WalletConnectV2Utility().createSavedSession(for: session, with: userWalletId.hexString)

                await self.storage.save(savedSession)
            }
            .sink()
            .store(in: &bag)
    }

    private func validateProposal(_ proposal: Session.Proposal) {
        let utils = WalletConnectV2Utility()
        guard utils.isAllChainsSupported(in: proposal.requiredNamespaces) else {
            let unsupportedBlockchains = utils.extractUnsupportedBlockchainNames(from: proposal.requiredNamespaces)
            displayErrorUI(.unsupportedBlockchains(unsupportedBlockchains))
            sessionRejected(with: proposal)
            return
        }

        do {
            let sessionNamespaces = try WalletConnectV2Utility().createSessionNamespaces(
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
        let message = messageComposer.makeMessage(for: proposal)
        uiDelegate.showScreen(with: WalletConnectUIRequest(
            event: .establishSession,
            message: message,
            positiveReactionAction: { [weak self] in
                self?.sessionAccepted(with: proposal.id, namespaces: namespaces)
            },
            negativeReactionAction: { [weak self] in
                self?.sessionRejected(with: proposal)
            }
        ))
    }

    private func displayErrorUI(_ error: WalletConnectV2Error) {
        let message = messageComposer.makeErrorMessage(error)
        uiDelegate.showScreen(with: WalletConnectUIRequest(
            event: .error,
            message: message,
            positiveReactionAction: { }
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
            }
            catch {
                AppLog.shared.error("[WC 2.0] Failed to reject WC connection with error: \(error)")
            }
        }
    }
}

extension WalletConnectV2Service: WalletConnectURLHandler {
    func canHandle(url: String) -> Bool {
        WalletConnectURI(string: url) != nil
    }

    func handle(url: URL) -> Bool {
        handle(url: url.absoluteString)
    }

    func handle(url: String) -> Bool {
        guard let uri = WalletConnectURI(string: url) else {
            return false
        }

        _canEstablishNewSessionPublisher.send(false)
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
            _canEstablishNewSessionPublisher.send(true)
        }
    }
}

extension WalletConnectV2Service {
    var canEstablishNewSessionPublisher: AnyPublisher<Bool, Never> {
        _canEstablishNewSessionPublisher.eraseToAnyPublisher()
    }

    var sessionsPublisher: AnyPublisher<[WalletConnectSession], Never> {
        Just([]).eraseToAnyPublisher()
    }

    var newSessions: AsyncStream<[WalletConnectSavedSession]> {
        get async {
            await storage.sessions
        }
    }

    func disconnectSession(with id: Int) async {
        guard let session = await storage.session(with: id) else { return }

        do {
            try await signApi.disconnect(topic: session.topic)
            await storage.remove(session)
        } catch {
            let internalError = WalletConnectV2ErrorMappingUtils().mapWCv2Error(error)
            if case .sessionForTopicNotFound = internalError {
                await storage.remove(session)
                return
            }
            AppLog.shared.error("[WC 2.0] Failed to disconnect session with topic: \(session.topic) with error: \(error)")
        }

    }
}
