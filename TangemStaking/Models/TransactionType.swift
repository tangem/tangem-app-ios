//
//  TransactionType.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public enum TransactionType: String, Hashable {
    case approval
    case stake
    case unstake
    case withdraw
}
