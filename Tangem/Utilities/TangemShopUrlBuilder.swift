//
//  TangemShopUrlBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct TangemShopUrlBuilder {
    func url(utmCampaign: TangemUTM.Campaign) -> URL {
        let appLanguageCode = Locale.current.language.languageCode?.identifier(.alpha2) ?? Locale.enLanguageCode
        var urlComponents = URLComponents(string: "https://buy.tangem.com/\(appLanguageCode)/")!
        urlComponents.queryItems = TangemUrlHelper.queryItems(utmCampaign: utmCampaign)
        return urlComponents.url!
    }
}
