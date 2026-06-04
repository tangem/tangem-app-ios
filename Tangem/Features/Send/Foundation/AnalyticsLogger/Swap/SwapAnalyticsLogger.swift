//
//  SwapAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol SwapAnalyticsLogger: SendBaseViewAnalyticsLogger,
    SendAmountAnalyticsLogger,
    SendFeeAnalyticsLogger,
    FeeSelectorAnalytics,
    SendSummaryAnalyticsLogger,
    SendFinishAnalyticsLogger,
    SendSwapProvidersAnalyticsLogger,
    SendApproveAnalyticsLogger,
    SwapManagementModelAnalyticsLogger {
    func setup(sendFeeInput: any SendFeeInput)
    func setup(sendSourceTokenInput: any SendSourceTokenInput)
    func setup(sendReceiveTokenInput: any SendReceiveTokenInput)
    func setup(sendSwapProvidersInput: any SendSwapProvidersInput)
}

/// Send-with-swap is a hybrid flow, so its logger combines the send and the swap surfaces.
protocol SendWithSwapAnalyticsLogger: SendAnalyticsLogger, SwapAnalyticsLogger {}
