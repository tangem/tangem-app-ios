//
//  Constants.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAnalytics
import TangemFoundation

enum AppConstants {
    static var isSmallScreen: Bool {
        UIScreen.main.bounds.width < 375 || UIScreen.main.bounds.height < 650
    }

    static let messageForTokensKey = "TokensSymmetricKey"
    static let maximumFractionDigitsForBalance = 8

    static let defaultScrollViewKeyboardDismissMode = UIScrollView.KeyboardDismissMode.onDrag

    static let minusSign: String = .minusSign // shorter stick
    static let enDashSign: String = .enDashSign // medium stick (en-dash)
    static let emDashSign: String = .emDashSign // longer stick (em-dash)
    static let unbreakableSpace = "\u{00a0}"
    static let infinitySign = "\u{221E}"
    static let tildeSign = "~"
    static let approximatelyEqualSign = "≈"
    static let dotSign = "•"
    static let rubCurrencyCode = "RUB"
    static let rubSign = "₽"
    static let usdCurrencyCode = "USD"
    static let usdSign = "$"
    static let audCurrencyCode = "AUD"
    static let eurCurrencyCode = "EUR"
    static let cadCurrencyCode = "CAD"
    static let gbpCurrencyCode = "GBP"

    static let sessionId = UUID().uuidString
    static let tosURL = URL(string: "https://tangem.com/tangem_tos.html")!
    static let tangemPayTermsAndLimitsURL = URL(string: "https://tangem.com/docs/en/tangem-visa-tariffs.pdf")!

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
