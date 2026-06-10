//
//  SendSummaryAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol SendSummaryAnalyticsLogger {
    func logUserDidTapOnValidator()
    func logUserDidTapOnProvider()

    func logSummaryStepOpened()

    func logTapAmountFraction(_ fraction: SwapAmountFraction)

    func logSwapTypeReselection(from: SwapFormVariant, to: SwapFormVariant)
    func logSwapTypeScreenOpened(variant: SwapFormVariant)
}

extension SendSummaryAnalyticsLogger {
    func logTapAmountFraction(_ fraction: SwapAmountFraction) {}

    func logSwapTypeReselection(from: SwapFormVariant, to: SwapFormVariant) {}
    func logSwapTypeScreenOpened(variant: SwapFormVariant) {}
}
