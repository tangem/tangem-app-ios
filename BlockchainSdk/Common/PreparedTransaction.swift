//
//  PreparedTransaction.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

public struct TransactionPayload {
    public let destinationAddress: String
    public let data: Data
    public let coinAmount: BigUInt
}
