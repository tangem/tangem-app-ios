//
//  YieldSupplyStatus.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

public struct YieldSupplyStatus {
    public let initialized: Bool
    public let active: Bool
    public let maxNetworkFee: BigUInt
}
