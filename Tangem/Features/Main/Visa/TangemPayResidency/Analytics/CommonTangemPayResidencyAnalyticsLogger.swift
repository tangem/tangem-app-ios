//
//  CommonTangemPayResidencyAnalyticsLogger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemPay

final class CommonTangemPayResidencyAnalyticsLogger: TangemPayResidencyAnalyticsLogger {
    func logCountrySelectScreenOpened() {
        log(.vaOnboardingCountrySelectScreenOpened)
    }

    func logCountrySelected(_ country: TangemPayGeoCountry, isSuggested: Bool) {
        log(.vaOnboardingCountrySelected, params: [
            .country: country.name,
            .ifSuggested: TangemPayResidencyAnalyticsValue(isSuggested).rawValue,
        ])
    }

    func logStateScreenOpened() {
        log(.vaOnboardingStateScreenOpened)
    }

    func logStateSelected(_ region: TangemPayGeoRegion, isSuggested: Bool) {
        log(.vaOnboardingStateSelected, params: [
            .residencyState: region.name,
            .ifSuggested: TangemPayResidencyAnalyticsValue(isSuggested).rawValue,
        ])
    }

    func logEligibilityCheckResult(isEligible: Bool, country: TangemPayGeoCountry, region: TangemPayGeoRegion?) {
        let result: TangemPayResidencyAnalyticsValue = isEligible ? .eligible : .notEligible

        var params: [Analytics.ParameterKey: String] = [
            .residencyResult: result.rawValue,
            .country: country.name,
        ]

        if let region {
            params[.residencyState] = region.name
        }

        log(.vaOnboardingEligibilityCheckResult, params: params)
    }

    func logRegionNotAvailableScreenOpened() {
        log(.vaOnboardingRegionNotAvailableScreenOpened)
    }

    func logSelectAnotherRegionTapped() {
        log(.vaOnboardingRegionNotAvailableSelectAnotherTapped)
    }

    func logJoinWaitlistTapped() {
        log(.vaOnboardingRegionNotAvailableJoinWaitlistTapped)
    }

    func logWaitlistScreenOpened() {
        log(.vaOnboardingWaitlistScreenOpened)
    }

    func logWaitlistSaved() {
        log(.vaOnboardingWaitlistSaved)
    }
}

// MARK: - Logging

private extension CommonTangemPayResidencyAnalyticsLogger {
    func log(_ event: Analytics.Event, params: [Analytics.ParameterKey: String] = [:]) {
        Analytics.log(event: event, params: params)
    }
}

// MARK: - Parameter values

private enum TangemPayResidencyAnalyticsValue: String {
    case yes
    case no
    case eligible
    case notEligible = "not_eligible"

    init(_ flag: Bool) {
        self = flag ? .yes : .no
    }
}
