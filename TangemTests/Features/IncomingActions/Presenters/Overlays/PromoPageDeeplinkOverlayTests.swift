//
//  PromoPageDeeplinkOverlayTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("Promo page overlay")
@MainActor
struct PromoPageDeeplinkOverlayTests {
    @Test(
        "With the toggle off no page is opened, however good its address",
        .enabled(if: !FeatureProvider.isAvailable(.promoPage))
    )
    func opensNothingWithToggleOff() {
        #expect(makeOverlay(page: Constants.page) == nil)
    }

    @Test(
        "With the toggle on a page that passes the address check is opened",
        .enabled(if: FeatureProvider.isAvailable(.promoPage))
    )
    func opensCheckedPage() {
        #expect(makeOverlay(page: Constants.page) != nil)
    }

    @Test(
        "With the toggle on a page that doesn't pass the address check opens nothing",
        .enabled(if: FeatureProvider.isAvailable(.promoPage)),
        arguments: ["http://promo.tangem.com/prize-draw-status/?success", "https://example.org", nil] as [String?]
    )
    func opensNothingForUncheckedPage(page: String?) {
        #expect(makeOverlay(page: page) == nil)
    }
}

// MARK: - Helpers

private extension PromoPageDeeplinkOverlayTests {
    enum Constants {
        static let page = "https://promo.tangem.com/prize-draw-status/?success"
    }

    func makeOverlay(page: String?) -> DeeplinkOverlayResult? {
        let context = DeeplinkOverlayContext(
            id: "promo_page",
            coordinatorFactory: CommonMainCoordinatorChildFactory(),
            present: { _ in },
            dismiss: {}
        )

        return PromoPageDeeplink(page: page).makeOverlay(in: context)
    }
}
