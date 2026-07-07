//
//  PriceAlertsOnboardingViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

// Skeleton: the full first-run onboarding content/behavior is [REDACTED_INFO].
final class PriceAlertsOnboardingViewModel: ObservableObject {
    let gotItAction: () -> Void

    init(gotItAction: @escaping () -> Void) {
        self.gotItAction = gotItAction
    }
}
