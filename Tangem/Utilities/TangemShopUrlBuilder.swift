//
//  TangemShopUrlBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import FirebaseAnalytics

struct TangemShopUrlBuilder {
    func url(utmCampaign: UTMCampaign) -> URL {
        var urlComponents = URLComponents(string: "https://buy.tangem.com")!

        let queryItemsDict = [
            "utm_source": "tangem-app",
            "utm_medium": "app",
            "utm_campaign": "\(utmCampaign.urlQueryValue)-\(Locale.appLanguageCode)",
            "utm_content": "devicelang-" + Locale.deviceLanguageCode,
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

// MARK: - Types

extension TangemShopUrlBuilder {
    enum UTMCampaign {
        case users
        case prospect
        case backup
        case upgrade

        var urlQueryValue: String {
            switch self {
            case .users: "users"
            case .prospect: "prospect"
            case .backup: "backup"
            case .upgrade: "upgrade"
            }
        }
    }
}
