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

// MARK: - Offers

protocol SendOnrampOffersAnalyticsLogger: SendOnrampProvidersAnalyticsLogger,
    SendOnrampPaymentMethodAnalyticsLogger {
    func logOnrampOfferButtonBuy(provider: OnrampProvider)
    func logOnrampRecentlyUsedClicked(provider: OnrampProvider)
    func logOnrampFastestMethodClicked(provider: OnrampProvider)
    func logOnrampBestRateClicked(provider: OnrampProvider)

    func logOnrampButtonAllOffers()
}

// MARK: - Providers

protocol SendOnrampProvidersAnalyticsLogger {
    func logOnrampProvidersScreenOpened()
    func logOnrampProviderChosen(provider: ExpressProvider)
}

// MARK: - Payment Method

protocol SendOnrampPaymentMethodAnalyticsLogger {
    func logOnrampPaymentMethodScreenOpened()
    func logOnrampPaymentMethodChosen(paymentMethod: OnrampPaymentMethod)
}

// MARK: - NAP

protocol SendOnrampNAPAnalyticsLogger {
    func logOnrampButtonNAP(amount: Decimal, currencyCode: String)
    func logOnrampNAPScreenOpened()
}
