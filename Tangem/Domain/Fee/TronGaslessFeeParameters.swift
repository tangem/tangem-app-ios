//
//  TronGaslessFeeParameters.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct TronGaslessFeeParameters: FeeParameters {
    let quoteId: String
    let feeRecipient: String
    let compensationToken: String
    let compensationAmountRaw: String
    let expiresAt: Date
    let energy: Int
    let bandwidth: Int
    let trxCost: String
}
