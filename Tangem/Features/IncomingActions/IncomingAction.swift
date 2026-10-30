//
//  IncomingAction.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum IncomingAction: Equatable {
    case walletConnect(WalletConnectRequestURI)
    case start // Run scan or request biometrics
    case dismissSafari(URL)
    /// A tangem.com page to open in the in-app browser.
    case externalLink(URL)
    case navigation(DeeplinkNavigationAction)
}

// MARK: - CustomStringConvertible

extension IncomingAction: CustomStringConvertible {
    var description: String {
        switch self {
        case .walletConnect:
            return "walletConnect"
        case .start:
            return "start"
        case .dismissSafari(let url):
            return "dismissSafari(\(url.absoluteStringWithoutQuery ?? ""))"
        case .externalLink(let url):
            return "externalLink(\(url.absoluteStringWithoutQuery ?? ""))"
        case .navigation(let navigationAction):
            return "navigation(\(navigationAction.rawCaseValue))"
        }
    }
}
