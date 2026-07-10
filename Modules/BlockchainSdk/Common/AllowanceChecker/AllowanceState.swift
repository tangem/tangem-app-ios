//
//  AllowanceState.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum AllowanceState: Hashable {
    case permissionRequired(ApproveTransactionData)
    case revokeAndPermissionRequired(revoke: ApproveTransactionData, approve: ApproveTransactionData)
    case approveTransactionInProgress
    case enoughAllowance
}
