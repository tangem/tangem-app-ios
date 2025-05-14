//
//  WCService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

protocol WCService {
    var canEstablishNewSessionPublisher: AnyPublisher<Bool, Never> { get }
    var newSessions: AsyncStream<[WalletConnectSavedSession]> { get async }
    var errorsPublisher: AnyPublisher<(error: WalletConnectV2Error, dAppName: String), Never> { get }

    func initialize()
    func reset()
    func openSession(with uri: WalletConnectRequestURI, source: Analytics.WalletConnectSessionSource)
    func disconnectSession(with id: Int) async
    func disconnectAllSessionsForUserWallet(with userWalletId: String)
    func updateSelectedWalletId(_ userWalletId: String)
    func updateSelectedNetworks(_ selectedNetworks: [BlockchainNetwork])
}

private struct WCServiceKey: InjectionKey {
    static var currentValue: WCService = CommonWCService()
}

extension InjectedValues {
    var wcService: WCService {
        get { Self[WCServiceKey.self] }
        set { Self[WCServiceKey.self] = newValue }
    }
}
