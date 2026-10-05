//
//  TangemPayResidencyAnalyticsLogger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemPay

protocol TangemPayResidencyAnalyticsLogger {
    func logCountrySelectScreenOpened()
    func logCountrySelected(_ country: TangemPayGeoCountry, isSuggested: Bool)

    func logStateScreenOpened()
    func logStateSelected(_ region: TangemPayGeoRegion, isSuggested: Bool)

    func logEligibilityCheckResult(isEligible: Bool, country: TangemPayGeoCountry, region: TangemPayGeoRegion?)

    func logRegionNotAvailableScreenOpened()
    func logSelectAnotherRegionTapped()
    func logJoinWaitlistTapped()

    func logWaitlistScreenOpened()
    func logWaitlistSaved()
}
