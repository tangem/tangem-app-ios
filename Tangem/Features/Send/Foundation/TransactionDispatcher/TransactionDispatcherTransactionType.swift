//
//  TransactionDispatcherTransactionType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemStaking

enum TransactionDispatcherTransactionType {
    case transfer(BSDKTransaction)
    case staking(StakingTransactionAction)
    case express(ExpressTransactionResult)
}
