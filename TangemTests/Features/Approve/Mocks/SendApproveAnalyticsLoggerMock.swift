//
//  SendApproveAnalyticsLoggerMock.swift
//  TangemTests
//
//  Created for Approve flow unit tests.
//

import BlockchainSdk
@testable import Tangem

final class SendApproveAnalyticsLoggerMock: SendApproveAnalyticsLogger {
    private(set) var logSwapButtonPermissionApproveCalls: [BSDKApprovePolicy] = []
    private(set) var logApproveTransactionSentCalls: [(policy: BSDKApprovePolicy, signerType: String, currentProviderHost: String)] = []

    func logSwapButtonPermissionApprove(policy: BSDKApprovePolicy) {
        logSwapButtonPermissionApproveCalls.append(policy)
    }

    func logApproveTransactionSent(policy: BSDKApprovePolicy, signerType: String, currentProviderHost: String) {
        logApproveTransactionSentCalls.append((policy, signerType, currentProviderHost))
    }
}
