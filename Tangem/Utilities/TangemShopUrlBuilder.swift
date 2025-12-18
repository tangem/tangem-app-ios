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
        var urlComponents = URLComponents(string: "https://buy.tangem.com/\(Locale.deviceLanguageCode)/")!
        urlComponents.queryItems = TangemUrlHelper.queryItems(utmCampaign: utmCampaign)
        return urlComponents.url!
    }
}
