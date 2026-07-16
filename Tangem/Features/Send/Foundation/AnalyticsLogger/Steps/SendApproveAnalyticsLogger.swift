//
//  SendApproveAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol SendApproveAnalyticsLogger {
    func logPermissionScreenOpened(isRevoke: Bool)
    func logSwapButtonPermissionApprove(policy: BSDKApprovePolicy)
    func logApproveTransactionSent(policy: BSDKApprovePolicy, signerType: String, currentProviderHost: String)
}
