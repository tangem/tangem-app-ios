//
//  MainNotificationsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemFoundation

enum MainNotificationSection: Identifiable {
    case marketing(PromotionNotificationsViewModel)
    case systemBanners([NotificationBannerItem])

    var id: String {
        switch self {
        case .marketing: "marketing"
        case .systemBanners: "systemBanners"
        }
    }
}

final class MainNotificationsViewModel: ObservableObject {
    @Published private(set) var sections: [MainNotificationSection] = []

    let promotionNotificationsViewModel: PromotionNotificationsViewModel

    @Injected(\.addFundsBannerVisibilityProvider) private var addFundsBannerVisibilityProvider: AddFundsBannerVisibilityProvider

    @Published private var systemBannerItems: [NotificationBannerItem] = []
    @Published private var tangemPayPromoItems: [NotificationBannerItem] = []
    @Published private var visibility: MainPromotionalVisibility

    private let isEnabled: Bool
    private let tangemPayPromoManager: NotificationManager?
    private let bannerMapper = MultiWalletNotificationBannerMapper()
    private var allowedVisibility: MainPromotionalVisibility = .all
    private var bag = Set<AnyCancellable>()

    init(
        isEnabled: Bool,
        promotionNotificationsManager: PromotionNotificationsManager,
        systemBannerItemsProvider: NotificationBannerItemsProvider,
        tangemPayPromoManager: NotificationManager?
    ) {
        self.isEnabled = isEnabled
        self.tangemPayPromoManager = tangemPayPromoManager
        visibility = isEnabled ? .hidden : .all
        promotionNotificationsViewModel = PromotionNotificationsViewModel(promotionNotificationsManager: promotionNotificationsManager)

        bindSections(systemBannerItemsProvider: systemBannerItemsProvider, tangemPayPromoManager: tangemPayPromoManager)
    }

    func bindVisibility(
        allowedVisibilityPublisher: AnyPublisher<MainPromotionalVisibility, Never>,
        balanceProvider: TotalBalanceProvider
    ) {
        guard isEnabled else { return }

        allowedVisibilityPublisher
            .receiveOnMain()
            .sink { [weak self] allowedVisibility in
                guard let self else { return }
                self.allowedVisibility = allowedVisibility

                if allowedVisibility < visibility {
                    setVisibility(allowedVisibility)
                }
            }
            .store(in: &bag)

        Publishers
            .CombineLatest(
                addFundsBannerVisibilityProvider
                    .shouldShowPublisher(for: balanceProvider)
                    .prefix(1),
                allowedVisibilityPublisher
            )
            .prefix(1)
            .receiveOnMain()
            .sink { [weak self] shouldShowAddFunds, allowedVisibility in
                guard let self else { return }
                self.allowedVisibility = allowedVisibility
                setVisibility(shouldShowAddFunds ? min(allowedVisibility, .tangemPayPromoOnly) : allowedVisibility)
            }
            .store(in: &bag)
    }

    func refresh() {
        guard isEnabled else { return }

        setVisibility(allowedVisibility)
    }
}

// MARK: - Private

private extension MainNotificationsViewModel {
    func bindSections(systemBannerItemsProvider: NotificationBannerItemsProvider, tangemPayPromoManager: NotificationManager?) {
        systemBannerItemsProvider.$items
            .assign(to: &$systemBannerItems)

        let promoItemsPublisher: AnyPublisher<[NotificationBannerItem], Never> = tangemPayPromoManager.map { manager in
            manager.notificationPublisher
                .removeDuplicates()
                .map { [bannerMapper] inputs in bannerMapper.mapItems(inputs) }
                .eraseToAnyPublisher()
        } ?? Just([]).eraseToAnyPublisher()

        promoItemsPublisher
            .receiveOnMain()
            .assign(to: &$tangemPayPromoItems)

        let marketing = promotionNotificationsViewModel

        Publishers
            .CombineLatest3($systemBannerItems, $tangemPayPromoItems, $visibility)
            .map { systemItems, promoItems, visibility -> [MainNotificationSection] in
                var sections: [MainNotificationSection] = []

                if visibility.isMarketingVisible {
                    sections.append(.marketing(marketing))
                }

                let banners = systemItems + (visibility.isTangemPayPromoVisible ? promoItems : [])
                if !banners.isEmpty {
                    sections.append(.systemBanners(banners))
                }

                return sections
            }
            .receiveOnMain()
            .assign(to: &$sections)
    }

    func setVisibility(_ newVisibility: MainPromotionalVisibility) {
        guard visibility != newVisibility else { return }

        visibility = newVisibility

        if !newVisibility.isMarketingVisible {
            promotionNotificationsViewModel.resetVisibilityTracking()
        }
    }
}
