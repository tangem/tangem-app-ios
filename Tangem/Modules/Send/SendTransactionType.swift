//
//  SendTransactionType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

enum SendTransactionType {
    case transfer(BSDKTransaction)
    case staking(StakingTransactionInfo)
}
