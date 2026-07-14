//
//  MarketingBannerNotificationInputFactoryTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemTestKit
import Testing
@testable import Tangem

@Suite("MarketingBannerNotificationInputFactory", .tags(.marketingBanners))
final class MarketingBannerNotificationInputFactoryTests: LeakTrackingTestSuite {
    private func makeBanner(deeplink: URL? = nil, isDismissible: Bool = false) -> MarketingBanner {
        MarketingBanner(
            id: 16,
            text: "Discover Bitcoin",
            iconURL: nil,
            backgroundColorHex: nil,
            placement: .standalone,
            action: deeplink.map(MarketingBanner.Action.deeplink),
            isDismissible: isDismissible
        )
    }

    private func makeSpy() -> IncomingActionHandlerSpy {
        trackForMemoryLeaks(IncomingActionHandlerSpy())
    }

    @Test("Banner with deeplink produces a tappable input that forwards the URL")
    func deeplinkBannerIsTappable() throws {
        let deeplink = URL(string: "tangem://swap")!
        let spy = makeSpy()

        let input = MarketingBannerNotificationInputFactory.makeInput(
            for: makeBanner(deeplink: deeplink),
            incomingActionHandler: spy,
            dismiss: { _ in }
        )

        guard case .tappable(let hasChevron, let action) = input.style else {
            Issue.record("Expected tappable style for a banner with deeplink")
            return
        }

        #expect(hasChevron)

        action(input.id)
        #expect(spy.handledURLs == [deeplink])
    }

    @Test("Banner without deeplink produces a plain input")
    func bannerWithoutDeeplinkIsPlain() {
        let input = MarketingBannerNotificationInputFactory.makeInput(
            for: makeBanner(),
            incomingActionHandler: makeSpy(),
            dismiss: { _ in }
        )

        #expect(input.style == .plain)
    }

    @Test("Dismiss action is wired only for dismissible banners")
    func dismissActionOnlyForDismissibleBanners() throws {
        let dismissedIds = OSAllocatedUnfairLock(initialState: [NotificationViewId]())
        let dismiss: NotificationView.NotificationAction = { id in
            dismissedIds.withLock { $0.append(id) }
        }

        let dismissibleInput = MarketingBannerNotificationInputFactory.makeInput(
            for: makeBanner(isDismissible: true),
            incomingActionHandler: makeSpy(),
            dismiss: dismiss
        )
        let permanentInput = MarketingBannerNotificationInputFactory.makeInput(
            for: makeBanner(isDismissible: false),
            incomingActionHandler: makeSpy(),
            dismiss: dismiss
        )

        let dismissAction = try #require(dismissibleInput.settings.dismissAction)
        dismissAction(dismissibleInput.id)

        #expect(dismissedIds.withLock { $0 } == [dismissibleInput.id])
        #expect(permanentInput.settings.dismissAction == nil)
    }
}
