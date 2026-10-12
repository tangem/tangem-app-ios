//
//  IncomingActionConstants.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum IncomingActionConstants {
    static let tangemHost = "tangem.com"
    static let tangemDomain = "https://tangem.com"

    /// Where AppsFlyer serves our links from. A link from them is as much ours as one from our own domain, but
    /// the domains themselves hold nothing to read: they forward, so a link naming nothing has nothing to show.
    static let attributionHosts: Set<String> = [
        "tangem.onelink.me",
        "join.tangem.com",
    ]

    /// The domains a link is accepted from, whichever destination it names. The app claims them in its
    /// entitlements, so nothing else can reach it as a link of ours.
    static let supportedExternalLinkHosts: Set<String> = Set([
        "tangem.com",
        "www.tangem.com",
        "buy.tangem.com",
        "app.tangem.com",
        "tangem.surveysparrow.com",
        "feedback.tangem.com",
    ]).union(attributionHosts)

    static let appScheme = "tangem://"
    static let ndefPath = "ndef"
    static let onrampPath = "/onramp"
    static let onrampRedirectURL = "\(tangemDomain)\(onrampPath)"
    static let externalRedirectURL = "\(tangemDomain)/redirect"
    static let appSchemeRedirectURL = "\(appScheme)redirect"
    static let incomingActionName = "action"

    /// Only the names more than one destination reads. Everything a single destination reads is declared by
    /// that destination.
    enum DeeplinkParams {
        static let tokenId = "token_id"
        static let networkId = "network_id"
        static let userWalletId = "user_wallet_id"
        static let derivationPath = "derivation_path"
        static let id = "id"
        static let promoCode = "promo_code"
    }

    enum DeeplinkType: String {
        case incomeTransaction = "income_transaction"
        case onrampStatusUpdate = "onramp_status_update"
        case swapStatusUpdate = "swap_status_update"
    }
}
