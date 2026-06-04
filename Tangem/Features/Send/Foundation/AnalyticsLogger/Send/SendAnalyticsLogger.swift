//
//  SendAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol SendAnalyticsLogger: SendManagementModelAnalyticsLogger,
    SendBaseViewAnalyticsLogger,
    SendAmountAnalyticsLogger,
    SendReceiveTokensListAnalyticsLogger,
    SendDestinationAnalyticsLogger,
    SendFeeAnalyticsLogger,
    FeeSelectorAnalytics,
    SendSwapProvidersAnalyticsLogger,
    SendSummaryAnalyticsLogger,
    SendFinishAnalyticsLogger,
    SendApproveAnalyticsLogger,
    SwapManagementModelAnalyticsLogger {
    func setup(sendDestinationInput: any SendDestinationInput)
    func setup(sendFeeInput: any SendFeeInput)
    func setup(sendSourceTokenInput: any SendSourceTokenInput)
    func setup(sendReceiveTokenInput: any SendReceiveTokenInput)
    func setup(sendSwapProvidersInput: any SendSwapProvidersInput)
}

// MARK: - Management Model

protocol SendManagementModelAnalyticsLogger {
    func logTransactionRejected(error: SendTxError)
    func logTransactionSent(
        amount: SendAmount?,
        additionalField: SendDestinationAdditionalField?,
        fee: FeeOption,
        signerType: String,
        currentProviderHost: String,
        tokenFee: TokenFee?
    )
}
