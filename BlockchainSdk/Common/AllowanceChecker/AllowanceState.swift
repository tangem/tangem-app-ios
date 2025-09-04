//
//  AllowanceState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum AllowanceState: Hashable {
    case permissionRequired(ApproveTransactionData)
    case approveTransactionInProgress
    case enoughAllowance
    case unsupported
}
