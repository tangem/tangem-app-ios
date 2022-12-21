//
//  WalletConnectService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class WalletConnectService {
    private var v1Service: WalletConnectV1Service? = nil
}

extension WalletConnectService: WalletConnectSetupManager {
    func initialize(with cardModel: CardViewModel) {
        guard cardModel.supportsWalletConnect else {
            return
        }

        v1Service = .init(with: cardModel)
    }

    func reset() {
        v1Service = nil
    }
}

extension WalletConnectService: WalletConnectSessionController {
    var canEstablishNewSessionPublisher: AnyPublisher<Bool, Never> {
        v1Service?.canEstablishNewSessionPublisher.eraseToAnyPublisher() ??
            Just(false).eraseToAnyPublisher()
    }
    var sessionsPublisher: AnyPublisher<[WalletConnectSession], Never> {
        v1Service?.sessionsPublisher ??
            Just([]).eraseToAnyPublisher()
    }
    func disconnectSession(with id: Int) {
        v1Service?.disconnectSession(with: id)
    }
}

extension WalletConnectService: WalletConnectURLHandler {
    func canHandle(url: String) -> Bool {
        v1Service?.canHandle(url: url) ?? false
    }

    func handle(url: URL) -> Bool {
        v1Service?.handle(url: url) ?? false
    }

    func handle(url: String) -> Bool {
        guard let url = URL(string: url) else {
            return false
        }

        return handle(url: url)
    }
}
