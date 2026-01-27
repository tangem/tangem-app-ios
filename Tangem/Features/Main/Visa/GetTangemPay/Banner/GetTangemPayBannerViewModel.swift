//
//  GetTangemPayBannerViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

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
