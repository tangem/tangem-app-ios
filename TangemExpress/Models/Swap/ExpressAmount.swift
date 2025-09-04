//
//  ExpressAmount.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public enum ExpressAmount {
    /// Usual transfer for CEX
    case transfer(amount: Decimal)

    /// For `DEX` / `DEX/Bridge` operations
    case dex(txValue: Decimal, txData: Data)
    
    /// For `DEX` specify operations
    case solanaDEX(txValue: Decimal?, txData: Data)
}
