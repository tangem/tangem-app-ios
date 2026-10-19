//
//  PromotionToken.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum PromotionToken: Equatable {
    case deeplink(networkId: String, currencySymbol: String)
    case bitcoin
}
