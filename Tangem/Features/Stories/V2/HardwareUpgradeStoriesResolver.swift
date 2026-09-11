//
//  HardwareUpgradeStoriesResolver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Answers whether the upgrade flow opens the promo stories before the Hardware wallet screen.
/// Both entry points — Main and Wallet Settings — must resolve through this type, so the two
/// branches of the experiment cannot drift apart.
struct HardwareUpgradeStoriesResolver {
    @Injected(\.experimentService) private var experimentService: ExperimentService

    /// Reads the experiment variant, which emits an Amplitude `$exposure` — call it on the upgrade
    /// tap and nowhere else. A closed release gate returns before the read, keeping the gate and the
    /// `control` variant apart in analytics: no exposure means the user never entered the experiment.
    func shouldShowStories() -> Bool {
        guard FeatureProvider.isAvailable(.hardwareUpgradeStories) else {
            return false
        }

        return experimentService.isOn(.hardwareUpgradeStories, variant: .treatment)
    }
}
