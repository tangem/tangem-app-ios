//
//  ExpressHistoryAsset.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressHistoryAsset: Hashable {
    public let currency: ExpressCurrency
    /// Expected amount, fixed at order time.
    public let amount: Decimal
    /// Final delivered amount. `nil` on the `from` side or until the order finalises.
    public let actualAmount: Decimal?
    public let decimals: Int
}
