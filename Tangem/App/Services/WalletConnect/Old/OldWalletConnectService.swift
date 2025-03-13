//
//  WalletConnectService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol OldWalletConnectService {
    var canEstablishNewSessionPublisher: AnyPublisher<Bool, Never> { get }
    var newSessions: AsyncStream<[WalletConnectSavedSession]> { get async }

    func initialize(with infoProvider: OldWalletConnectUserWalletInfoProvider)
    func reset()
    func openSession(with uri: WalletConnectRequestURI)
    func disconnectSession(with id: Int) async
    func disconnectAllSessionsForUserWallet(with userWalletId: String)
}

private struct OldWalletConnectServicingKey: InjectionKey {
    static var currentValue: OldWalletConnectService = OldCommonWalletConnectService()
}

extension InjectedValues {
    var walletConnectService: OldWalletConnectService {
        get { Self[OldWalletConnectServicingKey.self] }
        set { Self[OldWalletConnectServicingKey.self] = newValue }
    }
}
