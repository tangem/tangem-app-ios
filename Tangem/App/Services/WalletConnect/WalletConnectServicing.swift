//
//  WalletConnectServicing.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

typealias WalletConnectServicing = WalletConnectSetupManager & WalletConnectSessionController & WalletConnectURLHandler

protocol WalletConnectSetupManager {
    func initialize(with cardModel: CardViewModel)
    func reset()
}

protocol WalletConnectURLHandler: URLHandler {
    func canHandle(url: String) -> Bool
}

protocol WalletConnectSessionController {
    var canEstablishNewSessionPublisher: AnyPublisher<Bool, Never> { get }
    var sessionsPublisher: AnyPublisher<[WalletConnectSession], Never> { get }
    func disconnectSession(with id: Int)
}

private struct WalletConnectServicingKey: InjectionKey {
    static var currentValue: WalletConnectServicing = WalletConnectService()
}

extension InjectedValues {
    var walletConnectServicing: WalletConnectServicing {
        get { Self[WalletConnectServicingKey.self] }
        set { Self[WalletConnectServicingKey.self] = newValue }
    }

    var walletConnectSetupManager: WalletConnectSetupManager {
        get { Self[WalletConnectServicingKey.self] }
        set { }
    }

    var walletConnectURLHandler: WalletConnectURLHandler {
        get { Self[WalletConnectServicingKey.self] }
        set { }
    }

    var walletConnectSessionController: WalletConnectSessionController {
        get { Self[WalletConnectServicingKey.self] }
        set { }
    }
}
