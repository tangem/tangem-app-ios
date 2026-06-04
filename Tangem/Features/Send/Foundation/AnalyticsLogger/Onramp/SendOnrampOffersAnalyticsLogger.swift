//
//  SendOnrampOffersAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress

protocol SendOnrampOffersAnalyticsLogger: SendOnrampProvidersAnalyticsLogger,
    SendOnrampPaymentMethodAnalyticsLogger {
    func logOnrampOfferButtonBuy(provider: OnrampProvider)
    func logOnrampRecentlyUsedClicked(provider: OnrampProvider)
    func logOnrampFastestMethodClicked(provider: OnrampProvider)
    func logOnrampBestRateClicked(provider: OnrampProvider)

    func logOnrampButtonAllOffers()
}
