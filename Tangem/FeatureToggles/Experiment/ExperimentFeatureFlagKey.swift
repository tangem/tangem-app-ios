//
//  ExperimentFeatureFlagKey.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum ExperimentFeatureFlagKey: String {
    case newOnboardingFlow = "new_onboarding_flow" // For example
    case swapFormVariant = "swap_form_variant"
    case tangemPayOnboardingVariant = "visa_newonboarding_screen_june2026"
    case onboardingPushNotificationDoubleAsk = "twi_1403_onboarding_push_notification_double_ask"
    case mainPushNotificationDoubleAsk = "twi_1403_main_push_notification_double_ask"
}
