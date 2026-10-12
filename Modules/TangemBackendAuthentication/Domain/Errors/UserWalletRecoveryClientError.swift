//
//  UserWalletRecoveryClientError.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public enum UserWalletRecoveryClientError: Error {
    case requestNonceFailed(underlying: any Error)
}
