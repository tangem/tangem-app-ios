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
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.overlayViewPresentingStateProvider) private var overlayStateProvider: OverlayViewPresentingStateProvider
    @Injected(\.floatingSheetPresentingStateProvider) private var sheetStateProvider: FloatingSheetPresentingStateProvider

    // Used only in memory to reset the viewing session; never include the ID or its hash in event payloads.
    private var sessionWalletId: UserWalletId?
    private var sheetSize: ShtorkaSize = .collapsed
    private var canLogImpressions = false
    private var isContentVisible = false
    private var visibleProducts: [ProductCard: UserWalletId] = [:]
    private var shownProducts = Set<ProductCard>()
    private var subscription: AnyCancellable?

    init(container: any FeedContainer) {
        let isCoveredPublisher = Publishers.CombineLatest(
            overlayStateProvider.isPresentingPublisher,
            sheetStateProvider.hasPresentedSheetPublisher
        )
        .map { $0 || $1 }
        .removeDuplicates()

        subscription = Publishers.CombineLatest4(
            userWalletRepository.selectedUnlockedModelPublisher.map { $0?.userWalletId }.removeDuplicates(),
            container.sizePublisher,
            container.contentCollapsedPublisher,
            isCoveredPublisher
        )
        .receiveOnMain()
        .withWeakCaptureOf(self)
        .sink { analytics, state in
            let (walletId, size, isCollapsed, isCovered) = state
            if analytics.sessionWalletId != walletId {
                analytics.visibleProducts = analytics.visibleProducts.filter { $0.value == walletId }
            }
            // Actual collapse ends a viewing session even if an interrupted drag never changes the detent.
            if analytics.sessionWalletId != walletId || isCollapsed {
                analytics.shownProducts.removeAll()
            }
            analytics.sessionWalletId = walletId
            analytics.sheetSize = size
            analytics.canLogImpressions = walletId != nil && !isCollapsed && !isCovered
            analytics.logVisibleProducts()
        }
    }

    func updateContentVisibility(_ isVisible: Bool) {
        isContentVisible = isVisible
        logVisibleProducts()
    }

    func updateVisibility(of widget: FeedWidget, isVisible: Bool) {
        guard let product = ProductCard(widget: widget), let walletId = widget.walletId else { return }

        if isVisible, widget.loadingState.isSuccess {
            guard walletId == selectedWalletId else { return }

            visibleProducts[product] = walletId
        } else if visibleProducts[product] == walletId {
            visibleProducts[product] = nil
        }
        logVisibleProducts()
    }

    func logSelection(of widget: FeedWidget) {
        guard widget.loadingState.isSuccess else { return }

        if let walletId = widget.walletId, walletId != selectedWalletId {
            return
        }

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
    var selectedWalletId: UserWalletId? {
        guard let wallet = userWalletRepository.selectedModel, !wallet.isUserWalletLocked else { return nil }

        return wallet.userWalletId
    }

    func logVisibleProducts() {
        guard isContentVisible, canLogImpressions,
              let walletId = sessionWalletId, walletId == selectedWalletId else { return }

        for product in ProductCard.allCases where visibleProducts[product] == walletId {
            guard shownProducts.insert(product).inserted else { continue }

            log(.marketsProductCardShown, params: [.productCard: product.rawValue])
        }
    }

    func logProductClick(_ product: ProductCard) {
        log(.marketsProductCardClicked, params: [.productCard: product.rawValue])
    }

    func log(_ event: Analytics.Event, params: [Analytics.ParameterKey: String] = [:]) {
        guard let walletId = sessionWalletId, walletId == selectedWalletId else { return }

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
