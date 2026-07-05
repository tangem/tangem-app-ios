//
//  TokenItem+ZeroFee.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

extension TokenItem {
    /// A zero-valued fee denominated in this item's own currency. Useful as a placeholder or initial value.
    var zeroFee: Fee {
        Fee(Amount(with: blockchain, type: amountType, value: .zero))
    }
}
