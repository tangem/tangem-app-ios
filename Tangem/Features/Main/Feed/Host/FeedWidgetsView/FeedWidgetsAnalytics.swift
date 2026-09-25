//
//  FeedWidgetsAnalytics.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemUI

final class FeedWidgetsAnalytics {
    @Injected(\.overlayViewPresentingStateProvider) private var overlayStateProvider: OverlayViewPresentingStateProvider
    @Injected(\.floatingSheetPresentingStateProvider) private var sheetStateProvider: FloatingSheetPresentingStateProvider

    private var sheetSize: ShtorkaSize = .collapsed
    private var canLogImpressions = false
    private var isContentVisible = false
    private var visibleProducts = Set<ProductCard>()
    private var shownProducts = Set<ProductCard>()
    private var subscription: AnyCancellable?

    init(container: any FeedContainer) {
        let isCoveredPublisher = Publishers.CombineLatest(
            overlayStateProvider.isPresentingPublisher,
            sheetStateProvider.hasPresentedSheetPublisher
        )
        .map { $0 || $1 }
        .removeDuplicates()

        subscription = Publishers.CombineLatest3(
            container.sizePublisher,
            container.contentCollapsedPublisher,
            isCoveredPublisher
        )
        .receiveOnMain()
        .withWeakCaptureOf(self)
        .sink { analytics, state in
            let (size, isCollapsed, isCovered) = state
            // Actual collapse ends a viewing session even if an interrupted drag never changes the detent.
            if isCollapsed {
                analytics.shownProducts.removeAll()
            }
            analytics.sheetSize = size
            analytics.canLogImpressions = !isCollapsed && !isCovered
            analytics.logVisibleProducts()
        }
    }

    func updateContentVisibility(_ isVisible: Bool) {
        isContentVisible = isVisible
        logVisibleProducts()
    }

    func updateVisibility(of widget: FeedWidget, isVisible: Bool) {
        guard let product = ProductCard(widget: widget) else { return }

        if isVisible, widget.loadingState.isSuccess {
            visibleProducts.insert(product)
        } else {
            visibleProducts.remove(product)
        }
        logVisibleProducts()
    }

    func logSelection(of widget: FeedWidget) {
        guard widget.loadingState.isSuccess else { return }

        switch widget {
        case .startEarning:
            logProductClick(.earn)
        case .tangemPay:
            logProductClick(.tangemPay)
        case .referFriend:
            logProductClick(.referFriend)
        case .forYou:
            log(.marketsForYouClicked)
        case .addAccount:
            log(.walletSettingsButtonAddAccount, params: [.source: Analytics.ParameterValue.markets.rawValue])
        case .polymarket, .collectibles:
            break
        }
    }
}

private extension FeedWidgetsAnalytics {
    func logVisibleProducts() {
        guard isContentVisible, canLogImpressions else { return }

        for product in ProductCard.allCases where visibleProducts.contains(product) {
            guard shownProducts.insert(product).inserted else { continue }

            log(.marketsProductCardShown, params: [.productCard: product.rawValue])
        }
    }

    func logProductClick(_ product: ProductCard) {
        log(.marketsProductCardClicked, params: [.productCard: product.rawValue])
    }

    func log(_ event: Analytics.Event, params: [Analytics.ParameterKey: String] = [:]) {
        var params = params
        params[.shtorkaState] = switch sheetSize {
        case .collapsed: "Collapsed"
        case .medium: "Half"
        case .full: "Full"
        }
        Analytics.log(event: event, params: params)
    }

    enum ProductCard: String, CaseIterable {
        case tangemPay = "Tangem Pay"
        case earn = "Earn"
        case referFriend = "Refer a Friend"

        init?(widget: FeedWidget) {
            switch widget {
            case .tangemPay: self = .tangemPay
            case .startEarning: self = .earn
            case .referFriend: self = .referFriend
            case .forYou, .addAccount, .polymarket, .collectibles: return nil
            }
        }
    }
}
