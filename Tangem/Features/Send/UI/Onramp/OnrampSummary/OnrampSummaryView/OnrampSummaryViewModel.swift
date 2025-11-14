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

final class OnrampSummaryViewModel: ObservableObject, Identifiable {
    @Published private(set) var onrampAmountViewModel: OnrampAmountViewModel
    @Published private(set) var viewState: ViewState = .idle
    @Published private(set) var notificationInputs: [NotificationViewInput] = []
    @Published private(set) var notificationButtonIsLoading = false

    weak var router: OnrampSummaryRoutable?

    private let tokenItem: TokenItem
    private let interactor: OnrampSummaryInteractor
    private let notificationManager: NotificationManager
    private let analyticsLogger: SendOnrampOffersAnalyticsLogger

    private lazy var fiatPresetService = FiatPresetService()
    private lazy var onrampOfferViewModelBuilder = OnrampSuggestedOfferViewModelBuilder(tokenItem: tokenItem)

    private var bag: Set<AnyCancellable> = []

    init(
        onrampAmountViewModel: OnrampAmountViewModel,
        tokenItem: TokenItem,
        interactor: OnrampSummaryInteractor,
        notificationManager: NotificationManager,
        analyticsLogger: SendOnrampOffersAnalyticsLogger
    ) {
        self.onrampAmountViewModel = onrampAmountViewModel
        self.tokenItem = tokenItem
        self.interactor = interactor
        self.notificationManager = notificationManager
        self.analyticsLogger = analyticsLogger

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
        notificationManager
            .notificationPublisher
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
                recommended: offers.recommended.map { mapToRecommendedOnrampOfferViewModel(suggestedOfferType: $0) },
            ))
        }
    }

    func mapToRecentOnrampOfferViewModel(provider: OnrampProvider) -> OnrampOfferViewModel {
        let title = onrampOfferViewModelBuilder.mapToRecentOnrampOfferViewModelTitle(provider: provider)
        let viewModel = onrampOfferViewModelBuilder.mapToOnrampOfferViewModel(title: title, provider: provider) { [weak self] in
            self?.analyticsLogger.logOnrampRecentlyUsedClicked(provider: provider)
            self?.analyticsLogger.logOnrampOfferButtonBuy(provider: provider)
            self?.interactor.userDidRequestOnramp(provider: provider)
        }

        return viewModel
    }

    func mapToRecommendedOnrampOfferViewModel(suggestedOfferType: OnrampSummaryInteractorSuggestedOfferItem) -> OnrampOfferViewModel {
        let provider = suggestedOfferType.provider

        let title = onrampOfferViewModelBuilder.mapToRecommendedOnrampOfferViewModelTitle(suggestedOfferType: suggestedOfferType)
        let viewModel = onrampOfferViewModelBuilder.mapToOnrampOfferViewModel(title: title, provider: provider) { [weak self] in
            switch title {
            case .great: self?.analyticsLogger.logOnrampBestRateClicked(provider: provider)
            case .fastest: self?.analyticsLogger.logOnrampFastestMethodClicked(provider: provider)
            case .text, .bestRate: break
            }

            self?.analyticsLogger.logOnrampOfferButtonBuy(provider: provider)
            self?.interactor.userDidRequestOnramp(provider: provider)
        }

        return viewModel
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
        let recommended: [OnrampOfferViewModel]
    }
}
