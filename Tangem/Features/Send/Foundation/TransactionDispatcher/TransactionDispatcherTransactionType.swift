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
import TangemExpress
import TangemMacro

@RawCaseName
enum TransactionDispatcherTransactionType {
    case transfer(BSDKTransaction)
    case staking(StakingTransactionAction)
    case approve(data: ApproveTransactionData, fee: BSDKFee)
    case cex(data: ExpressTransactionData, fee: BSDKFee)
    case dex(data: ExpressTransactionData, fee: BSDKFee)
}
