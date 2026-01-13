//
//  PendingTransactionStatus.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemMacro

@CaseFlagable
public enum PendingTransactionStatus {
    case pending
    case executed
    case dropped
}
