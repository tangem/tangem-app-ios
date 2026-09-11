//
//  ExpressHistoryAsset+NormalizedAmount.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

extension ExpressHistoryAsset {
    var normalizedAmount: Decimal { actualAmount ?? amount }
}

extension OnrampHistoryCryptoAsset {
    var normalizedAmount: Decimal? { actualAmount ?? amount }
}
