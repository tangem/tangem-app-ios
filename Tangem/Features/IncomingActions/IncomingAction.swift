//
//  IncomingAction.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public enum IncomingAction: Equatable {
    case walletConnect(WalletConnectRequestURI)
    case start // Run scan or request biometrics
    case dismissSafari(URL)
    case referralProgram
    case navigation(DeeplinkNavigationAction)
    case tangemPayPush(TangemPayPushPayload)
}

public extension IncomingAction {
    var isPromoDeeplink: Bool {
        switch self {
        case .navigation(let action) where action.destination == .promo:
            true
        default:
            false
        }
    }
}
