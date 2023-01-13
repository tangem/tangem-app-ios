//
//  WalletConnectServicing.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol WalletConnectService: WalletConnectURLHandler {
    var canEstablishNewSessionPublisher: AnyPublisher<Bool, Never> { get }
    var sessionsPublisher: AnyPublisher<[WalletConnectSession], Never> { get }
    var newSessions: AsyncStream<[WalletConnectSavedSession]> { get async }

    func terminateAllSessions()
    func initialize(with cardModel: CardViewModel)
    func reset()
    func disconnectSession(with id: Int)
    func disconnectV2Session(with id: Int) async
}

protocol WalletConnectURLHandler: URLHandler {
    func canHandle(url: String) -> Bool
}

private struct WalletConnectServicingKey: InjectionKey {
    static var currentValue: WalletConnectService = CommonWalletConnectService()
}

extension InjectedValues {
    var walletConnectService: WalletConnectService {
        get { Self[WalletConnectServicingKey.self] }
        set { Self[WalletConnectServicingKey.self] = newValue }
    }
}
