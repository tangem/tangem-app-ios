//
//  CommonRateAppService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import StoreKit

class CommonRateAppService {
    private var userPrefsService: UserPrefsService = .init()
    private(set) var shouldShowRateAppWarning: Bool = false
    private let positiveBalanceTimeThreshold: TimeInterval = 3600 * 24 * 3
    private let positiveBalanceLaunchThreshold: Int = 3

    init() {
        if userPrefsService.didUserRespondToRateApp {
            return
        }

        let numberOfLaunches = userPrefsService.numberOfLaunches

        guard
            let positiveBalanceDate = userPrefsService.positiveBalanceAppearanceDate,
            let positiveBalanceLaunch = userPrefsService.positiveBalanceAppearanceLaunch
        else { return }

        guard
            (Date().timeIntervalSince1970 - positiveBalanceDate.timeIntervalSince1970) > positiveBalanceTimeThreshold,
            (numberOfLaunches - positiveBalanceLaunch) >= positiveBalanceLaunchThreshold
        else { return }

        guard let dismissAtLaunch = userPrefsService.dismissRateAppAtLaunch else {
            shouldShowRateAppWarning = true
            return
        }

        shouldShowRateAppWarning = (numberOfLaunches - dismissAtLaunch) >= 20
    }

    deinit {
        print("RateAppService deinit")
    }
}

extension CommonRateAppService: RateAppService {
    var shouldCheckBalanceForRateApp: Bool {
        !(userPrefsService.didUserRespondToRateApp ||
            userPrefsService.positiveBalanceAppearanceLaunch != nil)
    }

    func dismissRateAppWarning() {
        userPrefsService.dismissRateAppAtLaunch = userPrefsService.numberOfLaunches
        shouldShowRateAppWarning = false
    }

    func userReactToRateAppWarning(isPositive: Bool) {
        userPrefsService.didUserRespondToRateApp = true
        shouldShowRateAppWarning = false
        if isPositive {
            SKStoreReviewController.requestReview()
        }
    }

    func registerPositiveBalanceDate() {
        guard userPrefsService.positiveBalanceAppearanceDate == nil else { return }

        userPrefsService.positiveBalanceAppearanceDate = Date()
        userPrefsService.positiveBalanceAppearanceLaunch = userPrefsService.numberOfLaunches
    }
}
