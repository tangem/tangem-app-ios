//
//  OnrampSummaryViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemMacro
import TangemExpress
import TangemLocalization
import TangemFoundation
import TangemUI

final class OnrampSummaryViewModel: ObservableObject, Identifiable {
    @Injected(\.floatingSheetPresenter)
    private var floatingSheetPresenter: any FloatingSheetPresenter

    @Published private(set) var onrampAmountViewModel: OnrampAmountViewModel
    @Published private(set) var viewState: ViewState = .idle
    @Published private(set) var notificationInputs: [NotificationViewInput] = []
    @Published private(set) var notificationButtonIsLoading = false

    weak var router: OnrampSummaryRoutable?

    private let tokenItem: TokenItem
    private let interactor: OnrampSummaryInteractor
    private let notificationManager: NotificationManager
    private let marketingNotificationManager: any NotificationManager
    private let analyticsLogger: SendOnrampOffersAnalyticsLogger
    private let buyActionBuilder: OnrampOfferViewModelBuyActionBuilder

    private lazy var fiatPresetService = FiatPresetService()
    private lazy var onrampOfferViewModelBuilder = OnrampSuggestedOfferViewModelBuilder(tokenItem: tokenItem)

    private var bag: Set<AnyCancellable> = []

    init(
        onrampAmountViewModel: OnrampAmountViewModel,
        tokenItem: TokenItem,
        interactor: OnrampSummaryInteractor,
        notificationManager: NotificationManager,
        marketingNotificationManager: any NotificationManager,
        analyticsLogger: SendOnrampOffersAnalyticsLogger,
        buyActionBuilder: OnrampOfferViewModelBuyActionBuilder
    ) {
        self.onrampAmountViewModel = onrampAmountViewModel
        self.tokenItem = tokenItem
        self.interactor = interactor
        self.notificationManager = notificationManager
        self.marketingNotificationManager = marketingNotificationManager
        self.analyticsLogger = analyticsLogger
        self.buyActionBuilder = buyActionBuilder

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
}

// MARK: - Private

private extension OnrampSummaryViewModel {
    func bind() {
        Publishers.CombineLatest(
            marketingNotificationManager.notificationPublisher,
            notificationManager.notificationPublisher
        )
        .map { $0 + $1 }
        .receiveOnMain()
        .assign(to: &$notificationInputs)

        interactor
            .isLoadingPublisher
            .receiveOnMain()
            .assign(to: &$notificationButtonIsLoading)

        interactor
            .suggestedOffersPublisher
            .withWeakCaptureOf(self)
            .map { $0.mapToViewState(offers: $1) }
            .receiveOnMain()
            .assign(to: &$viewState)
    }

    func mapToViewState(offers: LoadingResult<OnrampSummaryInteractorSuggestedOffers, Never>) -> ViewState {
        switch offers {
        case .loading:
            return .loading

        case .success(let offers) where offers.isEmpty:
            let isEmptyTextField = onrampAmountViewModel.decimalNumberTextFieldViewModel.value ?? 0 <= 0
            if isEmptyTextField, let presets = fiatPresetService.presets() {
                return .presets(presets)
            }

            return .idle

        case .success(let offers):
            return .suggestedOffers(.init(
                recent: offers.recent.map { mapToRecentOnrampOfferViewModel(provider: $0) },
                recommended: offers.recommended.map { mapToRecommendedItem(suggestedOfferType: $0) },
            ))
        }
    }

    func mapToRecentOnrampOfferViewModel(provider: OnrampProvider) -> OnrampOfferViewModel {
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

        return onrampOfferViewModelBuilder.mapToOnrampOfferViewModel(title: title, provider: provider, buyAction: buyAction)
    }

    func mapToRecommendedItem(suggestedOfferType: OnrampSummaryInteractorSuggestedOfferItem) -> RecommendedItem {
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
        let footnote = isNativeApplePay ? makeIdentityVerificationFootnote(for: provider) : nil

        let viewModel = onrampOfferViewModelBuilder.mapToOnrampOfferViewModel(
            title: title,
            provider: provider,
            buyAction: buyAction,
            infoAction: infoAction,
            legalNotice: legalNotice
        )

        return RecommendedItem(viewModel: viewModel, footnote: footnote)
    }

    func makeIdentityVerificationFootnote(for provider: OnrampProvider) -> String {
        Localization.onrampNativePaymentIdentityVerification(provider.provider.name)
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
    }

    struct RecommendedItem: Hashable, Identifiable {
        let viewModel: OnrampOfferViewModel
        let footnote: String?

        var id: Int { hashValue }
    }
}
