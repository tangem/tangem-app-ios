//
//  SendAmountAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress

protocol SendAmountAnalyticsLogger {
    func logTapMaxAmount()
    func logTapConvertToAnotherToken()

    func logAmountStepOpened()
    func logAmountStepReopened()

    func logSwapErrorInsufficientBalance(screen: Analytics.ParameterValue)
    func logSwapErrorMinAmount(screen: Analytics.ParameterValue)
    func logSwapErrorMaxAmount(screen: Analytics.ParameterValue)
    func logSwapErrorExpressQuote(screen: Analytics.ParameterValue, errorDescription: String)
    func logSendWithSwapAmountScreenOpened(rateType: ExpressProviderRateType?)
}

extension SendAmountAnalyticsLogger {
    func logSwapErrorInsufficientBalance(screen: Analytics.ParameterValue) {}
    func logSwapErrorMinAmount(screen: Analytics.ParameterValue) {}
    func logSwapErrorMaxAmount(screen: Analytics.ParameterValue) {}
    func logSwapErrorExpressQuote(screen: Analytics.ParameterValue, errorDescription: String) {}
    func logSendWithSwapAmountScreenOpened(rateType: ExpressProviderRateType?) {}
}
