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

    init(onBannerTap: @escaping () -> Void) {
        self.onBannerTap = onBannerTap
    }

    func bannerTapped() {
        onBannerTap()
    }

    func closeBanner() {
        tangemPayAvailabilityRepository.userDidCloseGetTangemPayBanner()
    }
}
