//
//  WalletConnectServicing.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol WalletConnectService: URLHandler {
    var canEstablishNewSessionPublisher: AnyPublisher<Bool, Never> { get }
    var sessionsPublisher: AnyPublisher<[WalletConnectSession], Never> { get }

    func initialize(with cardModel: CardViewModel)
    func reset()

    func canHandle(url: String) -> Bool
    func disconnectSession(with id: Int)
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
