//
//  PromotionNotificationsManagerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import Testing
@testable import Tangem

@Suite("CommonPromotionNotificationsManager", .tags(.promotions), .serialized)
struct PromotionNotificationsManagerTests {
    private let userWalletId = UserWalletId(value: Data([0xAA]))

    @Test("A campaign banner without a deeplink still gets a button that opens the campaign")
    func campaignBannerWithoutDeeplinkHasButton() async {
        await withInjectedDependencies {
            let sut = CommonPromotionNotificationsManager(userWalletId: userWalletId, placement: .main)

            let event = sut.mapToPromotionNotificationEvent(item: makePromotion(campaignId: 7))

            guard case .openPromoCampaign(let buttonTitle) = event.buttonAction?.type else {
                Issue.record("Expected a promo campaign button")
                return
            }

            #expect(buttonTitle == "Open")
        }
    }

    @Test("A banner without a campaign gets a deeplink button only when it has a deeplink")
    func plainBannerButtonNeedsDeeplink() async {
        await withInjectedDependencies {
            let sut = CommonPromotionNotificationsManager(userWalletId: userWalletId, placement: .main)
            let deeplink = URL(string: "tangem://buy?currency=BTC")!

            let withoutDeeplink = sut.mapToPromotionNotificationEvent(item: makePromotion(campaignId: nil))
            let withDeeplink = sut.mapToPromotionNotificationEvent(item: makePromotion(campaignId: nil, deeplink: deeplink))

            #expect(withoutDeeplink.buttonAction == nil)

            guard case .openDeeplink(let url, _) = withDeeplink.buttonAction?.type else {
                Issue.record("Expected a deeplink button")
                return
            }

            #expect(url == deeplink)
        }
    }

    @Test("A disabled button stays hidden even on a campaign banner")
    func disabledButtonStaysHidden() async {
        await withInjectedDependencies {
            let sut = CommonPromotionNotificationsManager(userWalletId: userWalletId, placement: .main)

            let event = sut.mapToPromotionNotificationEvent(item: makePromotion(campaignId: 7, buttonEnabled: false))

            #expect(event.buttonAction == nil)
        }
    }
}

// MARK: - Helpers

private extension PromotionNotificationsManagerTests {
    func makePromotion(campaignId: Int?, deeplink: URL? = nil, buttonEnabled: Bool = true) -> Promotion {
        Promotion(
            id: 1,
            placeholder: .main,
            priority: nil,
            title: "Title",
            subtitle: "Subtitle",
            iconUrl: nil,
            deeplink: deeplink,
            buttonEnabled: buttonEnabled,
            buttonText: "Open",
            dismissable: true,
            campaignId: campaignId
        )
    }

    func withInjectedDependencies(operation: () async -> Void) async {
        await InjectedDependenciesIsolation.shared.run {
            let previousPromotionRepository = InjectedValues[\.promotionRepository]
            InjectedValues[\.promotionRepository] = FakePromotionRepository(promotions: [:])

            defer {
                InjectedValues[\.promotionRepository] = previousPromotionRepository
            }

            await operation()
        }
    }
}
