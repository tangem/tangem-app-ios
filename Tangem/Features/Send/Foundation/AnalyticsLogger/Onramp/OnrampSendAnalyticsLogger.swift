//
//  OnrampSendAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress

protocol OnrampSendAnalyticsLogger: OnrampManagementModelAnalyticsLogger,
    SendBaseViewAnalyticsLogger,
    SendOnrampOffersAnalyticsLogger,
    SendOnrampProvidersAnalyticsLogger,
    SendOnrampPaymentMethodAnalyticsLogger,
    SendOnrampNAPAnalyticsLogger,
    SendFinishAnalyticsLogger {
    func setup(onrampProvidersInput: OnrampProvidersInput)
}

// MARK: - Management Model

protocol OnrampManagementModelAnalyticsLogger {
    func logOnrampSelectedProvider(provider: OnrampProvider)
    func logOnrampVerifyScreenOpened(amount: Decimal, currencyCode: String)
}
