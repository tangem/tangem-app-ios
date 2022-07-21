//
//  ShopWebHelper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class ShopWebHelper {
    @Injected(\.geoIpService) private var geoIpService: GeoIpService

    var webShopUrl: URL? {
        switch geoIpService.regionCode {
        case "ru", "by":
            return URL(string: "https://tangem.com/ru/resellers/")
        default:
            return nil
        }
    }
}
