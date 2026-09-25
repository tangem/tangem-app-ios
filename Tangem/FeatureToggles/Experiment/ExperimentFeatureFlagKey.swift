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
    case hardwareUpgradeStories = "twi_1357_main_hardware_upgrade_stories"
    case polymarket = "twi_1576_polymarket"
}

enum ExperimentFeatureVariantKey: String {
    case treatment
    case control
    case on
}
