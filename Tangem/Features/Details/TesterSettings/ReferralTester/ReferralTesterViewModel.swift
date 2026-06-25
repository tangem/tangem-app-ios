//
//  ReferralTesterViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// Debug-only screen that reproduces the AppsFlyer referral deep link locally, so the Welcome flow
/// (stories hidden / mobile-wallet-first) can be exercised without relying on real attribution.
final class ReferralTesterViewModel: ObservableObject {
    @Injected(\.referralService) private var referralService: ReferralService
    @Injected(\.mobileWalletPromoService) private var mobileWalletPromoService: MobileWalletPromoService

    @Published var refcode: String = "ARABBTC"
    @Published private(set) var currentRefcode: String = ""
    @Published private(set) var isPromoActive: Bool = false

    init() {
        refreshState()
    }

    /// Mirrors `AppsFlyerDeepReferralHandler`: marks the mobile promo and persists the referral attribute.
    func simulateReferralDeepLink() {
        mobileWalletPromoService.setNeedsPromo()
        referralService.saveReferralIfNeeded(refcode: refcode, campaign: "debug_simulation")
        refreshState()
    }

    func clearReferral() {
        referralService.clearReferral()
        mobileWalletPromoService.resetPromo()
        refreshState()
    }

    private func refreshState() {
        currentRefcode = referralService.refcode ?? "—"
        isPromoActive = mobileWalletPromoService.shouldShowMobilePromoWalletSelector
    }
}
