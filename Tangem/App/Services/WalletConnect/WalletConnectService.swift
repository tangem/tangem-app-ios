//
//  WalletConnectService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class CommonWalletConnectService {
    @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging

    private var v1Service: WalletConnectV1Service?
    private var v2Service: WalletConnectV2Service?
}

extension CommonWalletConnectService: WalletConnectService {
    var canEstablishNewSessionPublisher: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest(
            v1Service?.canEstablishNewSessionPublisher.eraseToAnyPublisher() ?? Just(false).eraseToAnyPublisher(),
            v2Service?.canEstablishNewSessionPublisher.eraseToAnyPublisher() ?? Just(true).eraseToAnyPublisher()
        ).map { v1Can, v2Can in
            v1Can && v2Can
        }
        .eraseToAnyPublisher()
    }

    var sessionsPublisher: AnyPublisher<[WalletConnectSession], Never> {
        guard let v1Service = v1Service else {
            return Just([]).eraseToAnyPublisher()
        }

        return v1Service.sessionsPublisher
            .eraseToAnyPublisher()
    }

    var newSessions: AsyncStream<[WalletConnectSavedSession]> {
        get async {
            await v2Service?.newSessions ?? AsyncStream { $0.finish() }
        }
    }

    func initialize(with cardModel: CardViewModel) {
        guard cardModel.shouldShowWC else {
            return
        }

        // Note: If we are planning to write unit tests for each class this factory can be wrapped
        // with protocol and injected via initializer. But for now I think it'll be enough.
        let services = WalletConnectFactory().createWCServices(for: cardModel)

        v1Service = services.v1Service
        v2Service = services.v2Service
        incomingActionManager.becomeFirstResponder(self)
    }

    func reset() {
        incomingActionManager.resignFirstResponder(self)
        v1Service = nil
        v2Service = nil
    }

    func disconnectSession(with id: Int) {
        v1Service?.disconnectSession(with: id)
    }

    func disconnectV2Session(with id: Int) async {
        await v2Service?.disconnectSession(with: id)
    }

    func canOpenSession(with uri: WalletConnectRequestURI) -> Bool {
        switch uri {
        case .v1:
            return v1Service != nil
        case .v2:
            return v2Service != nil
        }
    }

    func openSession(with uri: WalletConnectRequestURI) {
        switch uri {
        case .v1(let v1URI):
            v1Service?.openSession(with: v1URI)
        case .v2(let v2URI):
            v2Service?.openSession(with: v2URI)
        }
    }
}

// MARK: - IncomingActionResponder

extension CommonWalletConnectService: IncomingActionResponder {
    func didReceiveIncomingAction(_ action: IncomingAction) -> Bool {
        guard case .walletConnect(let uri) = action, canOpenSession(with: uri) else {
            return false
        }

        openSession(with: uri)
        return true
    }
}
