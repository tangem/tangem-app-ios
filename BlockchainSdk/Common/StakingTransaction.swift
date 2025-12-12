//
//  StakingTransaction.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

public protocol StakingTransaction {
    var amount: Amount { get }
    var fee: Fee { get }
    var target: String? { get }
}
