//
//  GetTangemPayBannerViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

// [REDACTED_INFO]: legacy view model, paired with GetTangemPayBannerView. Delete after redesign cleanup.
struct GetTangemPayBannerViewModel {
    @Injected(
        \.tangemPayAvailabilityRepository
    )
    var tangemPayAvailabilityRepository: TangemPayAvailabilityRepository

    private let onBannerTap: () -> Void

    /// `onAppear` can fire repeatedly within one app session (scrolling, navigating back
    /// to Main, view re-creation), so the "banner shown" analytics is emitted only once
    /// per app launch.
    private static var didLogBannerShown = false

    init(onBannerTap: @escaping () -> Void) {
        self.onBannerTap = onBannerTap
    }

    func bannerTapped() {
        onBannerTap()
    }

    func onAppear() {
        guard !Self.didLogBannerShown else { return }
        Self.didLogBannerShown = true
        Analytics.log(.visaOnboardingPermanentBannerShowed)
    }

    func closeBanner() {
        tangemPayAvailabilityRepository.userDidCloseGetTangemPayBanner()
    }
}
