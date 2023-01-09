//
//  DeeplinkManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

public class DeeplinkManager {
    weak var delegate: DeeplinkManagerDelegate?
    public init() {}
}

// MARK: - DeeplinkManaging

extension DeeplinkManager: DeeplinkManaging {
    public func proceedDeeplink(url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
        let remouteRoute: RemoteRouteModel = .walletConnect(url)
        // Logic for parse wallet connect url
        // return false if deeplink will not proceed

        delegate?.didReceiveDeeplink(self, remoteRoute: remouteRoute)
        return true
    }

    public func setDelegate(_ delegate: DeeplinkManagerDelegate) {
        self.delegate = delegate
    }

    public func removeDelegate() {
        delegate = nil
    }
}
