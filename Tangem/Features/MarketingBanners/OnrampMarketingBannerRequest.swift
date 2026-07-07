//
//  OnrampMarketingBannerRequest.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct OnrampMarketingBannerRequest: Equatable {
    let destination: TokenItem
    let fiatCurrencyCode: String?
}
