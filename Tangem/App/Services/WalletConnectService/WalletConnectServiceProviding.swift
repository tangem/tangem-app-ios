//
//  WalletConnectServiceProviding.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol WalletConnectServiceProviding {
    var service: WalletConnectService? { get }

    func initialize(with cardModel: CardViewModel)
    func reset()
}

private struct WalletConnectServiceProviderKey: InjectionKey {
    static var currentValue: WalletConnectServiceProviding = WalletConnectServiceProvider()
}

extension InjectedValues {
    var walletConnectServiceProvider: WalletConnectServiceProviding {
        get { Self[WalletConnectServiceProviderKey.self] }
        set { Self[WalletConnectServiceProviderKey.self] = newValue }
    }
}
