//
//  SwapMarketingBannerRequest.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct SwapMarketingBannerRequest: Equatable {
    let source: TokenItem
    let destination: TokenItem
    let sourceAmount: Decimal?
}
