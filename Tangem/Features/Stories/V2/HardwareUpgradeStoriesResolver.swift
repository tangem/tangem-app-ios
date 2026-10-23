//
//  HardwareUpgradeStoriesResolver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Answers whether the upgrade flow opens the promo stories before the Hardware wallet screen.
/// Both entry points — Main and Wallet Settings — must resolve through this type, so the two
/// branches of the experiment cannot drift apart.
struct HardwareUpgradeStoriesResolver {
    @Injected(\.experimentService) private var experimentService: ExperimentService
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    /// Reads the experiment variant, which emits an Amplitude `$exposure` — call it on the upgrade
    /// tap and nowhere else.
    func shouldShowStories() -> Bool {
        guard !mobileWalletIds.isEmpty else {
            return false
        }

        return experimentService.isOn(.hardwareUpgradeStories, variant: .treatment)
    }

    func shouldPrefetchStories() async -> Bool {
        guard await experimentService.waitForVariants(ofWalletMatching: { mobileWalletIds.contains($0) }) else {
            return false
        }

        return experimentService.isOnWithoutExposure(.hardwareUpgradeStories, variant: .treatment)
    }
}

// MARK: - Private implementation

private extension HardwareUpgradeStoriesResolver {
    var mobileWalletIds: [UserWalletId] {
        userWalletRepository.models
            .filter { $0.config.productType == .mobileWallet }
            .map(\.userWalletId)
    }
}
