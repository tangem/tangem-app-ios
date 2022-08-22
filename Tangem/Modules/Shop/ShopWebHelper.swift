//
//  ShopWebHelper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class ShopWebHelper {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    var webShopUrl: URL? {
        switch tangemApiService.geoIpRegionCode {
        case LanguageCode.ru, LanguageCode.by:
            return URL(string: "https://tangem.com/ru/resellers/")
        default:
            return nil
        }
    }
}
