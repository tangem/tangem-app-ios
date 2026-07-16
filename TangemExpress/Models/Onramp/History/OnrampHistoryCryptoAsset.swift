//
//  OnrampHistoryCryptoAsset.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct OnrampHistoryCryptoAsset: Hashable {
    public let currency: ExpressCurrency
    /// Expected amount, promised by the provider.
    public let amount: Decimal?
    /// Final delivered amount. `nil` until the order finalises.
    public let actualAmount: Decimal?
    public let decimals: Int
}
