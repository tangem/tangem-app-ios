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

class WalletConnectV2Service {
    private var _canEstablishNewSessionPublisher: CurrentValueSubject<Bool, Never> = .init(true)
    @Published private  var sessions: [WalletConnectSession] = []

    private let uiDelegate: WalletConnectUIDelegate
    private let messageComposer: WalletConnectV2MessageComposable
    private let pairApi: PairingInteracting
    private let signApi: SignClient

    private let factory = WCDefaultSocketFactory()

    private var bag = Set<AnyCancellable>()

    init(
        with cardModel: CardViewModel,
        uiDelegate: WalletConnectUIDelegate = WalletConnectAlertUIDelegate(),
        messageComposer: WalletConnectV2MessageComposable = WalletConnectV2MessageComposer()
    ) {
        self.uiDelegate = uiDelegate
        self.messageComposer = messageComposer

        Networking.configure(projectId: "c0e14e9fac0113e872980f2aae3354de", socketFactory: factory)
        Pair.configure(metadata: AppMetadata(name: "Tangem", description: "NFC crypto wallet", url: "tangem.com", icons: ["https://user-images.githubusercontent.com/24321494/124071202-72a00900-da58-11eb-935a-dcdab21de52b.png"]))
        pairApi = Pair.instance
        signApi = Sign.instance
        subscribeToMessages()
    }

    func subscribeToMessages() {
        signApi.sessionProposalPublisher
            .receive(on: DispatchQueue.main)
            .sink { sessionProposal in
                print("[WC] Session proposal: \(sessionProposal)")
                print("[RESPONDER] WC: Did receive session proposal")
            }.store(in: &bag)
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

        pairClient(with: uri)
        return true
    }

    private func pairClient(with uri: WalletConnectURI) {
        print("[WC] Trying to pair client: \(uri)")
        Task {
            do {
                try await pairApi.pair(uri: uri)
                print("[WC] Established pair for \(uri)")
            } catch {
                print("[WC] Failed to connect to \(uri). Reason: \(error)")
            }

        }
    }
}

extension WalletConnectV2Service: WalletConnectSessionController {
    var canEstablishNewSessionPublisher: AnyPublisher<Bool, Never> {
        _canEstablishNewSessionPublisher.eraseToAnyPublisher()
    }

    var sessionsPublisher: AnyPublisher<[WalletConnectSession], Never> {
        $sessions
            .eraseToAnyPublisher()
    }

    func disconnectSession(with id: Int) {

    }
}
