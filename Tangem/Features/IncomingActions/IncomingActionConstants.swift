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
    static let appTangemHost = "app.tangem.com"
    static let appTangemDomain = "https://app.tangem.com"
    static let tangemDomain = "https://tangem.com"

    static let supportedExternalLinkHosts: Set<String> = [
        "tangem.com",
        "www.tangem.com",
        "buy.tangem.com",
        "app.tangem.com",
        "tangem.surveysparrow.com",
        "feedback.tangem.com",
    ]

    static let newsPath = "/news"
    static let universalLinkScheme = "tangem://"
    static let ndefPath = "ndef"
    static let onrampPath = "/onramp"
    static let onrampRedirectURL = "\(tangemDomain)\(onrampPath)"
    static let externalRedirectURL = "\(tangemDomain)/redirect"
    static let universalLinkRedirectURL = "\(universalLinkScheme)redirect"
    static let externalSuccessURL = "\(tangemDomain)/success"
    static let incomingActionName = "action"

    enum DeeplinkParams {
        static let type = "type"
        static let name = "name"
        static let tokenId = "token_id"
        static let networkId = "network_id"
        static let userWalletId = "user_wallet_id"
        static let walletId = "wallet_id"
        static let derivationPath = "derivation_path"
        static let transactionId = "transaction_id"
        static let entry = "entry"
        static let id = "id"
        static let newsId = "news_id"
        static let categoryId = "category_id"
        static let promoCode = "promo_code"
        static let refcode = "ref"
        static let campaign = "campaign"
        static let order = "order"
        static let interval = "interval"
        static let earnType = "earn_type"
        static let surveyToken = "token"
    }

    enum DeeplinkDestination: String, CaseIterable {
        case token
        case staking
        case yield
        case referral
        case markets
        case tokenChart = "token_chart"
        case tokenExchanges = "token_exchanges"
        case buy
        case swap
        case sell
        case link
        case onboardVisa = "onboard-visa"
        case promo
        case payApp = "pay-app"
        case news
        /// Universal link to a specific article: `https://tangem.com/news/{category}/{id}-{slug}`.
        /// Not resolvable from a `tangem://` host — produced only by `NewsIncomingLinkParser`.
        case newsArticle = "news-article"
        case earn
        case survey
    }

    enum DeeplinkType: String {
        case incomeTransaction = "income_transaction"
        case onrampStatusUpdate = "onramp_status_update"
        case swapStatusUpdate = "swap_status_update"
    }
}
