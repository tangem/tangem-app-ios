//
//  OnrampHistoryFiatAsset.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct OnrampHistoryFiatAsset: Hashable {
    public let currencyCode: String
    public let amount: Decimal
}
