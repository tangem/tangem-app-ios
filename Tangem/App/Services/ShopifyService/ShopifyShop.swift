//
//  ShopifyShop.swift
//  TangemShopify
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

struct ShopifyShop: Decodable {
    let domain: String
    let storefrontApiKey: String
    let merchantID: String?
}
