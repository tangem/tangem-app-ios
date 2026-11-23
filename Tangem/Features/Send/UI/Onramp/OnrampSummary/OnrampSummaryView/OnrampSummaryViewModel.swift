//
//  OnrampSummaryViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemMacro
import TangemExpress
import TangemLocalization
import TangemFoundation
import TangemUI

final class OnrampSummaryViewModel: ObservableObject, Identifiable {
    @Injected(\.floatingSheetPresenter)
    private var floatingSheetPresenter: any FloatingSheetPresenter

    @Injected(\.incomingActionHandler)
    private var incomingActionHandler: IncomingActionHandler

    @Published private(set) var onrampAmountViewModel: OnrampAmountViewModel
    @Published private(set) var viewState: ViewState = .idle
    @Published private(set) var notificationInputs: [NotificationViewInput] = []
    @Published private(set) var standaloneMarketingBanners: [StandaloneMarketingBannerViewModel]?
    @Published private(set) var topCallToActionBanners: [CallToActionMarketingBanner] = []

    @Published private(set) var notificationButtonIsLoading = false
    @Published private(set) var restrictedRegionName: String?

    weak var router: OnrampSummaryRoutable?

    private let tokenItem: TokenItem
    private let interactor: OnrampSummaryInteractor
    private let notificationManager: NotificationManager
    private let marketingBannerManager: OnrampMarketingBannerManager
    private let linkedBannersPublisher: AnyPublisher<[MarketingBanner], Never>
    private let analyticsLogger: SendOnrampOffersAnalyticsLogger
    private let buyActionBuilder: OnrampOfferViewModelBuyActionBuilder
    private let fiatPresetService: FiatPresetService
    private let isCountryUnsupportedPublisher: AnyPublisher<Bool, Never>
    private let restrictedRegionPublisher: AnyPublisher<OnrampCountry?, Never>

    private let isRecommendedSlotReplacementEnabled = FeatureProvider.isAvailable(.onrampImprovements)
    private lazy var onrampOfferViewModelBuilder = OnrampSuggestedOfferViewModelBuilder(tokenItem: tokenItem)
    private var bannerIdsOffTop: Set<Int> = []
    private var bag = Set<AnyCancellable>()

    init(
        onrampAmountViewModel: OnrampAmountViewModel,
        tokenItem: TokenItem,
        interactor: OnrampSummaryInteractor,
        notificationManager: NotificationManager,
        marketingBannerManager: OnrampMarketingBannerManager,
        linkedBannersPublisher: AnyPublisher<[MarketingBanner], Never>,
        analyticsLogger: SendOnrampOffersAnalyticsLogger,
        buyActionBuilder: OnrampOfferViewModelBuyActionBuilder,
        fiatPresetService: FiatPresetService,
        isCountryUnsupportedPublisher: AnyPublisher<Bool, Never>,
        restrictedRegionPublisher: AnyPublisher<OnrampCountry?, Never>
    ) {
        self.onrampAmountViewModel = onrampAmountViewModel
        self.tokenItem = tokenItem
        self.interactor = interactor
        self.notificationManager = notificationManager
        self.marketingBannerManager = marketingBannerManager
        self.linkedBannersPublisher = linkedBannersPublisher
        self.analyticsLogger = analyticsLogger
        self.buyActionBuilder = buyActionBuilder
        self.fiatPresetService = fiatPresetService
        self.isCountryUnsupportedPublisher = isCountryUnsupportedPublisher
        self.restrictedRegionPublisher = restrictedRegionPublisher

        bind()
    }

    func usedDidTapPreset(preset: FiatPresetService.Preset) {
        onrampAmountViewModel.decimalNumberTextFieldViewModel.update(value: preset.amount)
        interactor.userDidChangeFiat(amount: preset.amount)
    }

    func openOnrampSettingsView() {
        router?.openOnrampSettingsView()
    }

    func userDidTapAllOffersButton() {
        analyticsLogger.logOnrampButtonAllOffers()
        router?.openOnrampAllOffers()
    }

    func userDidTapCallToActionBanner(action: CallToActionMarketingBannerAction) {
        marketingBannerManager.perform(action)
    }
}

// MARK: - Private

private extension OnrampSummaryViewModel {
    func bind() {
        notificationManager.notificationPublisher
            .receiveOnMain()
            .assign(to: &$notificationInputs)

        marketingBannerManager.standaloneBannersPublisher
            .map { $0.nilIfEmpty }
            .assign(to: &$standaloneMarketingBanners)

        let offersWithLayout = marketingBannerManager.callToActionBannersPublisher
            .map { [isRecommendedSlotReplacementEnabled] banners in
                CallToActionLayout(banners: banners, replacesSlots: isRecommendedSlotReplacementEnabled)
            }
            .removeDuplicates()
            .flatMapLatest { [interactor] layout in
                interactor
                    .suggestedOffersPublisher(replacedSlots: Set(layout.bannersBySlot.keys))
                    .map { (offers: $0, layout: layout) }
            }

        interactor
            .isLoadingPublisher
            .receiveOnMain()
            .assign(to: &$notificationButtonIsLoading)

        restrictedRegionPublisher
            .map { $0.map { BuyAndSwapRestrictionBannerViewModel.regionName(of: $0.identity) } }
            .receiveOnMain()
            .assign(to: &$restrictedRegionName)

        Publishers.CombineLatest3(
            offersWithLayout,
            linkedBannersPublisher,
            Publishers.CombineLatest(isCountryUnsupportedPublisher, restrictedRegionPublisher.map { $0 == nil })
        )
        .withWeakCaptureOf(self)
        .map { viewModel, values in
            let ((offers, layout), banners, (isCountryUnsupported, isBuyEnabled)) = values
            let viewState = viewModel.mapToViewState(
                offers: offers,
                linkedBanners: banners,
                slotBanners: layout.bannersBySlot,
                isCountryUnsupported: isCountryUnsupported,
                isBuyEnabled: isBuyEnabled
            )

            return (viewState, layout)
        }
        .receiveOnMain()
        .withWeakCaptureOf(self)
        .sink { viewModel, values in
            viewModel.apply(viewState: values.0, layout: values.1)
        }
        .store(in: &bag)
    }

    func apply(viewState: ViewState, layout: CallToActionLayout) {
        bannerIdsOffTop = Self.bannerIdsOffTop(for: viewState, keptWhileLoading: bannerIdsOffTop)
        topCallToActionBanners = layout.all.filter { !bannerIdsOffTop.contains($0.id) }
        self.viewState = viewState
    }

    func mapToViewState(
        offers: LoadingResult<OnrampSummarySuggestedOffers, Never>,
        linkedBanners: [MarketingBanner],
        slotBanners: [MarketingBanner.RecommendedSlot: CallToActionMarketingBanner],
        isCountryUnsupported: Bool,
        isBuyEnabled: Bool
    ) -> ViewState {
        switch offers {
        case .loading:
            return .loading

        case .success(let offers) where offers.recent == nil && offers.recommended.isEmpty:
            let isEmptyTextField = onrampAmountViewModel.decimalNumberTextFieldViewModel.value ?? 0 <= 0
            if isEmptyTextField, !isCountryUnsupported, let presets = fiatPresetService.presets() {
                return .presets(presets)
            }

            return .idle

        case .success(let offers):
            return .suggestedOffers(.init(
                recent: offers.recent.map {
                    mapToRecentOnrampOfferViewModel(provider: $0, linkedBanners: linkedBanners, isBuyEnabled: isBuyEnabled)
                },
                recommended: offers.recommended.compactMap { entry -> RecommendedItem? in
                    switch entry {
                    case .offer(let item):
                        return .offer(mapToRecommendedOffer(suggestedOfferType: item, linkedBanners: linkedBanners, isBuyEnabled: isBuyEnabled))
                    case .replacedSlot(let slot):
                        return slotBanners[slot].map(RecommendedItem.banner)
                    }
                },
                hasMoreOffers: isRecommendedSlotReplacementEnabled ? offers.hasMoreOffers : true
            ))
        }
    }

    func mapToRecentOnrampOfferViewModel(
        provider: OnrampProvider,
        linkedBanners: [MarketingBanner],
        isBuyEnabled: Bool
    ) -> OnrampOfferViewModel {
        let title = onrampOfferViewModelBuilder.mapToRecentOnrampOfferViewModelTitle(provider: provider)
        let buyAction = buyActionBuilder.make(
            provider: provider,
            onWillBuy: { [weak self] in
                self?.analyticsLogger.logOnrampOfferButtonBuy(provider: provider)
                self?.analyticsLogger.logOnrampRecentlyUsedClicked(provider: provider)
            },
            onWidgetBuy: { [weak self] in
                self?.interactor.userDidRequestOnramp(provider: provider)
            }
        )

        let legalNotice = buyAction.isNativeApplePay ? OnrampNativePaymentLegalLinks.legalNotice(for: provider) : nil

        return onrampOfferViewModelBuilder.mapToOnrampOfferViewModel(
            title: title,
            provider: provider,
            buyAction: buyAction,
            legalNotice: legalNotice,
            linkedBanner: linkedBanner(for: provider, in: linkedBanners),
            isBuyEnabled: isBuyEnabled
        )
    }

    func linkedBanner(for provider: OnrampProvider, in banners: [MarketingBanner]) -> LinkedMarketingBannerViewModel? {
        LinkedMarketingBannerViewModelFactory.make(
            from: banners,
            providerId: provider.provider.id,
            incomingActionHandler: incomingActionHandler
        )
    }

    func mapToRecommendedOffer(
        suggestedOfferType: OnrampSummaryInteractorSuggestedOfferItem,
        linkedBanners: [MarketingBanner],
        isBuyEnabled: Bool
    ) -> OnrampOfferViewModel {
        let provider = suggestedOfferType.provider
        let title = onrampOfferViewModelBuilder.mapToRecommendedOnrampOfferViewModelTitle(suggestedOfferType: suggestedOfferType)

        let buyAction = buyActionBuilder.make(
            provider: provider,
            onWillBuy: { [weak self] in
                self?.analyticsLogger.logOnrampOfferButtonBuy(provider: provider)
                switch title {
                case .great: self?.analyticsLogger.logOnrampBestRateClicked(provider: provider)
                case .fastest: self?.analyticsLogger.logOnrampFastestMethodClicked(provider: provider)
                case .text, .bestRate: break
                }
            },
            onWidgetBuy: { [weak self] in
                self?.interactor.userDidRequestOnramp(provider: provider)
            }
        )

        let isNativeApplePay = suggestedOfferType.isNativeApplePay
        let infoAction: (() -> Void)? = isNativeApplePay ? { [weak self] in self?.openProviderRequirementsSheet() } : nil
        let legalNotice = isNativeApplePay ? OnrampNativePaymentLegalLinks.legalNotice(for: provider) : nil

        return onrampOfferViewModelBuilder.mapToOnrampOfferViewModel(
            title: title,
            provider: provider,
            buyAction: buyAction,
            infoAction: infoAction,
            legalNotice: legalNotice,
            linkedBanner: linkedBanner(for: provider, in: linkedBanners),
            isBuyEnabled: isBuyEnabled
        )
    }

    func openProviderRequirementsSheet() {
        let viewModel = OnrampProviderRequirementsBottomSheetViewModel()
        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }
}

// MARK: - ViewState

extension OnrampSummaryViewModel {
    @RawCaseName
    enum ViewState: Hashable, Identifiable {
        case idle
        case presets([FiatPresetService.Preset])
        case loading
        case suggestedOffers(SuggestedOffers)
    }

    struct SuggestedOffers: Hashable {
        let recent: OnrampOfferViewModel?
        let recommended: [RecommendedItem]
        let hasMoreOffers: Bool
    }

    enum RecommendedItem: Hashable, Identifiable {
        case offer(OnrampOfferViewModel)
        case banner(CallToActionMarketingBanner)

        var id: String {
            switch self {
            case .offer(let viewModel): "offer-\(viewModel.id)"
            case .banner(let banner): "banner-\(banner.id)"
            }
        }
    }
}

// MARK: - Call-to-action layout

extension OnrampSummaryViewModel {
    static func bannerIdsOffTop(for viewState: ViewState, keptWhileLoading: Set<Int>) -> Set<Int> {
        switch viewState {
        case .loading:
            return keptWhileLoading
        case .idle, .presets:
            return []
        case .suggestedOffers(let offers):
            return Set(offers.recommended.compactMap { item in
                if case .banner(let banner) = item {
                    return banner.id
                }

                return nil
            })
        }
    }

    struct CallToActionLayout: Equatable {
        let all: [CallToActionMarketingBanner]
        let bannersBySlot: [MarketingBanner.RecommendedSlot: CallToActionMarketingBanner]

        init(banners: [CallToActionMarketingBanner], replacesSlots: Bool = true) {
            var bannersBySlot: [MarketingBanner.RecommendedSlot: CallToActionMarketingBanner] = [:]

            for banner in banners where replacesSlots {
                if let slot = banner.replacedSlot, bannersBySlot[slot] == nil {
                    bannersBySlot[slot] = banner
                }
            }

            all = banners
            self.bannersBySlot = bannersBySlot
        }
    }
}
