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
    private var v1Service: WalletConnectV1Service?
    private var v2Service: WalletConnectV2Service?
}

extension CommonWalletConnectService: WalletConnectService {
    var canEstablishNewSessionPublisher: AnyPublisher<Bool, Never> {
        guard
            let v1Service = v1Service,
            let v2Service = v2Service
        else {
            return Just(false).eraseToAnyPublisher()
        }

        return Publishers.CombineLatest(
            v1Service.canEstablishNewSessionPublisher,
            v2Service.canEstablishNewSessionPublisher
        ).map { (v1Can, v2Can) in
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
            await v2Service!.newSessions
        }
    }

    func terminateAllSessions() {
        Task {
            try await v2Service!.terminateAllSessions()
        }
    }

    func initialize(with cardModel: CardViewModel) {
        guard cardModel.supportsWalletConnect else {
            return
        }

        v1Service = .init(with: cardModel)
        v2Service = .init(with: cardModel)
    }

    func reset() {
        v1Service = nil
        v2Service = nil
    }

    func disconnectSession(with id: Int) {
        v1Service?.disconnectSession(with: id)
    }

    func disconnectV2Session(with id: Int) async {
        await v2Service?.disconnectSession(with: id)
    }

    func canHandle(url: String) -> Bool {
        serviceToHandleLink(url) != nil
    }

    func handle(url: URL) -> Bool {
        handle(url: url.absoluteString)
    }

    func handle(url: String) -> Bool {
        guard let service = serviceToHandleLink(url) else {
            return false
        }

        return service.handle(url: url)
    }

    private func serviceToHandleLink(_ link: String) -> WalletConnectURLHandler? {
        if v2Service?.canHandle(url: link) ?? false {
            return v2Service
        }

        if v1Service?.canHandle(url: link) ?? false {
            return v1Service
        }

        return nil
    }
}
