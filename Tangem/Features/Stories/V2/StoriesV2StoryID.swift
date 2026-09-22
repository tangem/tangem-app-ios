//
//  StoriesV2StoryID.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// The single place in the app that knows remote story wire ids.
enum StoriesV2StoryID: String, CaseIterable {
    case hardwareUpgrade = "hardware_upgrade"
    case firstTimeSwap = "first-time-swap-v2"
    case firstTimeYieldPromo = "first-time-yield-promo"
    /// The same story as `firstTimeSwap` under the name the batch example uses — only one of the
    /// two is live, pending an answer from the backend.
    case swapFirstTry = "swap_first_try"
}

extension StoriesV2StoryID {
    /// Warmed unconditionally on app start; flow-specific stories are prefetched on demand.
    static let prefetchedOnAppStart: [StoriesV2StoryID] = [
        .hardwareUpgrade,
    ]
}
