//
//  TransactionType.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public enum TransactionType: String, Hashable {
    case enter
    case stake
    case reinvest
    case claim
    case claimRewards
    case unstake
}
