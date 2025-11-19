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

enum ExpressTransactionResult {
    /// Uncompiled BSDK Transaction for sign
    case `default`(BSDKTransaction)

    /// Compiled BSDK Transaction for sign
    case compiled(Data)
}
