//
//  RealAssetsFeaturedItem.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

struct RealAssetsFeaturedItem: Identifiable {
    let id: String
    let name: String
    let symbol: String
    let imageURL: URL?
    let price: String
    let priceChangeState: PriceChangeView.State
    let onTap: () -> Void
}
