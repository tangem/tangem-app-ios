//
//  WalletConnectDeeplinkManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct WalletConnectDeeplinkManager {
    weak var delegate: WalletConnectDeeplinkManagerDelegate?
    public init() {}
}

// MARK: - WalletConnectDeeplinkManaging

extension WalletConnectDeeplinkManager: WalletConnectDeeplinkManaging {
    public func proceedDeeplink(url: URL, options _: UIScene.OpenURLOptions?) {
        let remouteRoute: RemoteRouteModel = .url(url)
        // Logic for parse wallet connect url

        delegate?.didReceiveDeeplink(self, remoteRoute: remouteRoute)
    }
    
    public func setDelegate(_ delegate: DeeplinkManagerDelegate) {
        self.delegate = delegate
    }

    public func removeDelegate() {
        delegate = nil
    }
}
