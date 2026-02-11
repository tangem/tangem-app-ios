//
//  ExpressTransactionDataType.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public enum ExpressTransactionDataType {
    /// Usual transfer for CEX
    case cex(data: ExpressTransactionData)

    /// For `DEX` / `DEX/Bridge` operations
    case dex(data: ExpressTransactionData)
}
