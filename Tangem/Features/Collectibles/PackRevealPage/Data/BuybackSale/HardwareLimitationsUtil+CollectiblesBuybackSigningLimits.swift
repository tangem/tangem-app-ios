//
//  HardwareLimitationsUtil+CollectiblesBuybackSigningLimits.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemCollectibles

extension HardwareLimitationsUtil: CollectiblesBuybackSigningLimits {
    func canSign(_ transaction: Data) throws -> Bool {
        try canHandleTransaction(CollectiblesChainEnvironment.usdcTokenItem, transaction: transaction)
    }
}
