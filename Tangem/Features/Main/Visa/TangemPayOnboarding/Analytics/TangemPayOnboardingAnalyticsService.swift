//
//  TangemPayOnboardingAnalyticsService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

protocol TangemPayOnboardingAnalyticsService {
    func logBundleScreenOpened()
    func logNewOnboardingScreenOpened()
    func logTermsTapped()
}

struct CommonTangemPayOnboardingAnalyticsService: TangemPayOnboardingAnalyticsService {
    func logBundleScreenOpened() {
        Analytics.log(
            .visaOnboardingVisaShortForHWActivationScreenOpened,
            analyticsSystems: .all,
            contextParams: .custom(.mobileWallet)
        )
    }

    func logNewOnboardingScreenOpened() {
        Analytics.log(.visaOnboardingVisaNewOnboardingPageOpened, analyticsSystems: .all)
    }

    func logTermsTapped() {
        Analytics.log(.visaOnboardingButtonVisaViewTerms)
    }
}

// MARK: - Injection

private struct TangemPayOnboardingAnalyticsServiceKey: InjectionKey {
    static var currentValue: TangemPayOnboardingAnalyticsService = CommonTangemPayOnboardingAnalyticsService()
}

extension InjectedValues {
    var tangemPayOnboardingAnalytics: TangemPayOnboardingAnalyticsService {
        get { Self[TangemPayOnboardingAnalyticsServiceKey.self] }
        set { Self[TangemPayOnboardingAnalyticsServiceKey.self] = newValue }
    }
}
