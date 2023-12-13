//
//  CommonLegacyRateAppService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import StoreKit

class CommonLegacyRateAppService {
    private(set) var shouldShowRateAppWarning: Bool = false
    private let positiveBalanceTimeThreshold: TimeInterval = 3600 * 24 * 3
    private let positiveBalanceLaunchThreshold: Int = 3

    init() {
        if AppSettings.shared.didUserRespondToRateApp {
            return
        }

        let numberOfLaunches = AppSettings.shared.numberOfLaunches

        guard
            let positiveBalanceDate = AppSettings.shared.positiveBalanceAppearanceDate,
            let positiveBalanceLaunch = AppSettings.shared.positiveBalanceAppearanceLaunch
        else { return }

        guard
            (Date().timeIntervalSince1970 - positiveBalanceDate.timeIntervalSince1970) > positiveBalanceTimeThreshold,
            (numberOfLaunches - positiveBalanceLaunch) >= positiveBalanceLaunchThreshold
        else { return }

        guard let dismissAtLaunch = AppSettings.shared.dismissRateAppAtLaunch else {
            shouldShowRateAppWarning = true
            return
        }

        shouldShowRateAppWarning = (numberOfLaunches - dismissAtLaunch) >= 20
    }

    deinit {
        AppLog.shared.debug("RateAppService deinit")
    }
}

// MARK: - LegacyRateAppService protocol conformance

extension CommonLegacyRateAppService: LegacyRateAppService {
    var shouldCheckBalanceForRateApp: Bool {
        !(AppSettings.shared.didUserRespondToRateApp ||
            AppSettings.shared.positiveBalanceAppearanceLaunch != nil)
    }

    func dismissRateAppWarning() {
        AppSettings.shared.dismissRateAppAtLaunch = AppSettings.shared.numberOfLaunches
        shouldShowRateAppWarning = false
    }

    func userReactToRateAppWarning(isPositive: Bool) {
        AppSettings.shared.didUserRespondToRateApp = true
        shouldShowRateAppWarning = false
        if isPositive {
            Analytics.log(.noticeRateTheAppButtonTapped)

            if let scene = UIApplication.activeScene {
                DispatchQueue.main.async {
                    SKStoreReviewController.requestReview(in: scene)
                }
            }
        }
    }

    func registerPositiveBalanceDate() {
        guard AppSettings.shared.positiveBalanceAppearanceDate == nil else { return }

        AppSettings.shared.positiveBalanceAppearanceDate = Date()
        AppSettings.shared.positiveBalanceAppearanceLaunch = AppSettings.shared.numberOfLaunches
    }
}

// MARK: - Dependency injection

private struct RateAppServiceKey: InjectionKey {
    static var currentValue: LegacyRateAppService = CommonLegacyRateAppService()
}

extension InjectedValues {
    var rateAppService: LegacyRateAppService {
        get { Self[RateAppServiceKey.self] }
        set { Self[RateAppServiceKey.self] = newValue }
    }
}
