//
//  Constants.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import FirebaseAnalytics
import Foundation
import UIKit

enum AppConstants {
    static var isSmallScreen: Bool {
        UIScreen.main.bounds.width < 375 || UIScreen.main.bounds.height < 650
    }

    static let messageForTokensKey = "TokensSymmetricKey"
    static let maximumFractionDigitsForBalance = 8

    static let defaultScrollViewKeyboardDismissMode = UIScrollView.KeyboardDismissMode.onDrag

    static let minusSign = "−" // shorter stick
    static let dashSign = "—" // longer stick (em-dash)
    static let unbreakableSpace = "\u{00a0}"
    static let infinitySign = "\u{221E}"
    static let tildeSign = "~"
    static let dotSign = "•"
    static let rubCurrencyCode = "RUB"
    static let rubSign = "₽"
    static let usdCurrencyCode = "USD"
    static let usdSign = "$"

    static let sessionId = UUID().uuidString

    #warning("[REDACTED_TODO_COMMENT]")
    static let feeExplanationTangemBlogURL = URL(string: "https://tangem.com/en/blog/post/what-is-a-transaction-fee-and-why-do-we-need-it/")!

    static let tosURL = URL(string: "https://tangem.com/tangem_tos.html")!

    static func getWebShopUrl(isExistingUser: Bool) -> URL {
        var urlComponents = URLComponents(string: "https://buy.tangem.com")!
        let campaignPrefix = isExistingUser ? "users-" : "prospect-"

        let queryItemsDict = [
            "utm_source": "tangem",
            "utm_medium": "app",
            "utm_campaign": campaignPrefix + Locale.appLanguageCode,
            "utm_content": "devicelang-" + Locale.deviceLanguageCode(),
            "app_instance_id": FirebaseAnalytics.Analytics.appInstanceID(),
        ]

        urlComponents.queryItems = queryItemsDict
            .compactMap { key, value in
                value.map { value in
                    URLQueryItem(name: key, value: value)
                }
            }

        return urlComponents.url!
    }
}
