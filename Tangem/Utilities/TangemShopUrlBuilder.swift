//
//  TangemShopUrlBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct TangemShopUrlBuilder {
    @Injected(\.referralService) private var referralService: ReferralService

    func url(utmCampaign: TangemUTM.Campaign) -> URL {
        let appLanguageCode = Locale.current.language.languageCode?.identifier(.alpha2) ?? Locale.enLanguageCode
        var urlComponents = URLComponents(string: "https://buy.tangem.com/\(appLanguageCode)/")!

        var queryItems = TangemUrlHelper.queryItems(utmCampaign: utmCampaign)
        if let refCode = referralService.refcode {
            queryItems.append(URLQueryItem(name: "promocode", value: refCode))
        }

        urlComponents.queryItems = queryItems
        return urlComponents.url!
    }
}
