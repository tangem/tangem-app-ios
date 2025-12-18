//
//  TangemUrlHelper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import FirebaseAnalytics

enum TangemUrlHelper {
    static func queryItems(utmCampaign: TangemUTM.Campaign) -> [URLQueryItem] {
        let systemLanguageCode = Locale.systemLanguageCode
        let deviceLanguageCode = Locale.deviceLanguageCode

        let utmCampaignValue = "\(queryItemString(utmCampaign: utmCampaign))-\(deviceLanguageCode)"
        let utmContentValue = "devicelang-\(systemLanguageCode)"
        let appInstanceIdValue = FirebaseAnalytics.Analytics.appInstanceID()

        return [
            URLQueryItem(name: "utm_source", value: "tangem-app"),
            URLQueryItem(name: "utm_medium", value: "app"),
            URLQueryItem(name: "utm_campaign", value: utmCampaignValue),
            URLQueryItem(name: "utm_content", value: utmContentValue),
            appInstanceIdValue.map { URLQueryItem(name: "app_instance_id", value: $0) },
        ].compactMap { $0 }
    }

    private static func queryItemString(utmCampaign: TangemUTM.Campaign) -> String {
        switch utmCampaign {
        case .users: "users"
        case .prospect: "prospect"
        case .backup: "backup"
        case .upgrade: "upgrade"
        case .articles: "articles"
        }
    }
}

enum TangemUTM {
    enum Campaign {
        case users
        case prospect
        case backup
        case upgrade
        case articles
    }
}
