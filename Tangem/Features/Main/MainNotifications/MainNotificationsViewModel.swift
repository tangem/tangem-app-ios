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
    @Published private var isPromotionalVisible: Bool

    private let isEnabled: Bool
    private let tangemPayPromoManager: NotificationManager?
    private let bannerMapper = MultiWalletNotificationBannerMapper()
    private var hasSystemCard = false
    private var bag = Set<AnyCancellable>()

    init(
        isEnabled: Bool,
        promotionNotificationsManager: PromotionNotificationsManager,
        systemBannerItemsProvider: NotificationBannerItemsProvider,
        tangemPayPromoManager: NotificationManager?
    ) {
        self.isEnabled = isEnabled
        self.tangemPayPromoManager = tangemPayPromoManager
        isPromotionalVisible = !isEnabled
        promotionNotificationsViewModel = PromotionNotificationsViewModel(promotionNotificationsManager: promotionNotificationsManager)

        bindSections(systemBannerItemsProvider: systemBannerItemsProvider, tangemPayPromoManager: tangemPayPromoManager)
    }

    func bindVisibility(hasSystemCardPublisher: AnyPublisher<Bool, Never>, balanceProvider: TotalBalanceProvider) {
        guard isEnabled else { return }

        hasSystemCardPublisher
            .receiveOnMain()
            .sink { [weak self] hasSystemCard in
                guard let self else { return }
                self.hasSystemCard = hasSystemCard

                if hasSystemCard {
                    setPromotionalVisible(false)
                }
            }
            .store(in: &bag)

        Publishers
            .CombineLatest(
                addFundsBannerVisibilityProvider
                    .shouldShowPublisher(for: balanceProvider)
                    .prefix(1)
                    .mapToVoid(),
                hasSystemCardPublisher
            )
            .prefix(1)
            .receiveOnMain()
            .sink { [weak self] _, hasSystemCard in
                guard let self else { return }
                self.hasSystemCard = hasSystemCard
                setPromotionalVisible(!hasSystemCard)
            }
            .store(in: &bag)
    }

    func refresh() {
        guard isEnabled else { return }

        setPromotionalVisible(!hasSystemCard)
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
            .CombineLatest3($systemBannerItems, $tangemPayPromoItems, $isPromotionalVisible)
            .map { systemItems, promoItems, isPromotionalVisible -> [MainNotificationSection] in
                var sections: [MainNotificationSection] = []

                if isPromotionalVisible {
                    sections.append(.marketing(marketing))
                }

                let banners = systemItems + (isPromotionalVisible ? promoItems : [])
                if !banners.isEmpty {
                    sections.append(.systemBanners(banners))
                }

                return sections
            }
            .receiveOnMain()
            .assign(to: &$sections)
    }

    func setPromotionalVisible(_ visible: Bool) {
        guard isPromotionalVisible != visible else { return }

        isPromotionalVisible = visible

        if !visible {
            promotionNotificationsViewModel.resetVisibilityTracking()
        }
    }
}
