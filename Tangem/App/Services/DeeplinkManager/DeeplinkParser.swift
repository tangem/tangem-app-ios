//
//  DeeplinkParser.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

public class DeeplinkParser {
    public weak var delegate: DeeplinkParserDelegate?
    public init() {}
}

// MARK: - DeeplinkParsing

extension DeeplinkParser: DeeplinkParsing {
    public func handleDeeplink(url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
        let remouteRoute: RemoteRouteModel = .walletConnect(url)
        // Logic for parse wallet connect url
        // return false if deeplink will not proceed

        delegate?.didReceiveDeeplink(self, remoteRoute: remouteRoute)
        return true
    }
}
