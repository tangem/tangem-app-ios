//
//  WalletConnectDeeplinkManaging.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol WalletConnectDeeplinkManagerDelegate: AnyObject {
    func didReceiveDeeplink(_ manager: WalletConnectDeeplinkManaging, remoteRoute: RemoteRouteModel)
}

protocol WalletConnectDeeplinkManaging {
    func proceedDeeplink(url: URL, options: UIScene.OpenURLOptions?)
    func setDelegate(_ delegate: WalletConnectDeeplinkManagerDelegate)
    func removeDelegate()
}

private struct WalletConnectDeeplinkManagingKey: InjectionKey {
    static var currentValue: WalletConnectDeeplinkManaging = WalletConnectDeeplinkManager()
}

extension InjectedValues {
    var walletConnectDeeplinkManager: WalletConnectDeeplinkManaging {
        get { Self[WalletConnectDeeplinkManagingKey.self] }
        set { Self[WalletConnectDeeplinkManagingKey.self] = newValue }
    }
}
