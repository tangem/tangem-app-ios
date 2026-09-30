//
//  FeedTabsViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
@testable import Tangem

@Suite("FeedTabsViewModel")
@MainActor
struct FeedTabsViewModelTests {
    @Test("A link moves the page the feed renders, not only the chips")
    func selectingByKindMovesThePage() {
        let viewModel = makeSUT()

        viewModel.selectTab(kind: .earn)

        #expect(viewModel.selectedTab.kind == .earn)
        #expect(viewModel.pages.map(\.tab.kind) == [.earn])
        #expect(viewModel.pages.map(\.offset) == [0])
    }

    @Test("A kind this build has no tab for lands on the default one")
    func unknownKindLandsOnTheDefault() {
        let viewModel = makeSUT()

        viewModel.selectTab(kind: .realAssets)

        #expect(viewModel.selectedTab.kind == .predictions)
        #expect(viewModel.pages.map(\.tab.kind) == [.predictions])
    }

    @Test("A tap leaves the slide to the pager")
    func tappingLeavesTheSlideToThePager() {
        let viewModel = makeSUT()

        viewModel.onSelectTab(viewModel.tabs[1])

        #expect(viewModel.selectedTab.kind == .earn)
        #expect(viewModel.pages.map(\.tab.kind) == [.predictions])
    }
}

// MARK: - Helpers

private extension FeedTabsViewModelTests {
    func makeSUT() -> FeedTabsViewModel {
        let earn = EarnFeedViewModel(
            promotionNotificationsManager: PromotionNotificationsManagerStub(),
            router: EarnRouterStub()
        )

        return FeedTabsViewModel(tabs: [.predictions, .earn(earn)])
    }
}

// MARK: - Stubs

private final class PromotionNotificationsManagerStub: PromotionNotificationsManager {
    var notificationInputs: [NotificationViewInput] { get async { [] } }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        Empty<[NotificationViewInput], Never>(completeImmediately: false).eraseToAnyPublisher()
    }

    func loadPromotions() async {}
    func setupManager(with delegate: NotificationTapDelegate?) {}
    func dismissNotification(with id: NotificationViewId) {}
}

private final class EarnRouterStub: EarnFeedRoutable {
    func routeOnTokenResolved(_ resolution: EarnTokenResolution, source: EarnOpportunitySource) {}
    func openPortfolioToken(_ walletModel: any WalletModel) {}
    func openNetworksFilter() {}
    func openTypesFilter() {}
}
