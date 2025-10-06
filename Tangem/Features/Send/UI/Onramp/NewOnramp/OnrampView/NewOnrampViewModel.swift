//
//  NewOnrampViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemExpress
import TangemLocalization
import TangemFoundation

final class NewOnrampViewModel: ObservableObject, Identifiable {
    @Published private(set) var onrampAmountViewModel: NewOnrampAmountViewModel

    var viewState: ViewState {
        if suggestedOffersIsVisible, let suggestedOffers {
            return .suggestedOffers(suggestedOffers)
        }

        if onrampAmountViewModel.decimalNumberTextFieldViewModel.value ?? 0 <= 0,
           let presets = fiatPresetService.presets() {
            return .presets(presets)
        }

        return .continueButton
    }

    @Published private(set) var notificationInputs: [NotificationViewInput] = []
    @Published private(set) var notificationButtonIsLoading = false
    @Published private(set) var shouldShowLegalText: Bool = true

    @Published private var suggestedOffersIsVisible: Bool = false
    @Published private var suggestedOffers: SuggestedOffers?
    var continueButtonIsDisabled: Bool { suggestedOffers == nil }

    weak var router: OnrampSummaryRoutable?

    private let tokenItem: TokenItem
    private let interactor: NewOnrampInteractor
    private let notificationManager: NotificationManager
    private let analyticsLogger: SendOnrampOffersAnalyticsLogger

    private lazy var fiatPresetService = FiatPresetService()
    private lazy var onrampOfferViewModelBuilder = OnrampOfferViewModelBuilder(tokenItem: tokenItem)

    private var bag: Set<AnyCancellable> = []

    init(
        onrampAmountViewModel: NewOnrampAmountViewModel,
        tokenItem: TokenItem,
        interactor: NewOnrampInteractor,
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
        interactor.update(fiat: preset.amount)
    }

    func usedDidTapContinue() {
        shouldShowLegalText = false
        suggestedOffersIsVisible = true
    }

    func openOnrampSettingsView() {
        router?.openOnrampSettingsView()
    }

    func userDidTapAllOffersButton() {
        analyticsLogger.logOnrampButtonAllOffers()
        router?.onrampStepRequestEditProvider()
    }
}

// MARK: - Private

private extension NewOnrampViewModel {
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
            .isLoadingPublisher
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { $0.updateViewState(isLoading: $1) }
            .store(in: &bag)

        interactor
            .suggestedOffersPublisher
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { $0.setupOnrampOfferViewModels(offers: $1) }
            .store(in: &bag)
    }

    func setupOnrampOfferViewModels(offers: LoadingResult<OnrampInteractorSuggestedOffer?, Never>) {
        switch offers {
        case .loading, .success(.none):
            suggestedOffers = nil

        case .success(.some(let offers)):
            suggestedOffers = .init(
                recent: offers.recent.map { mapToRecentOnrampOfferViewModel(provider: $0) },
                recommended: offers.recommended.map { mapToRecommendedOnrampOfferViewModel(provider: $0) },
                shouldShowAllOffersButton: offers.shouldShowAllOffersButton
            )
        }
    }

    func mapToRecentOnrampOfferViewModel(provider: OnrampProvider) -> OnrampOfferViewModel {
        let viewModel = onrampOfferViewModelBuilder.mapToOnrampOfferViewModel(provider: provider) { [weak self] in
            self?.analyticsLogger.logOnrampRecentlyUsedClicked(provider: provider)
            self?.analyticsLogger.logOnrampOfferButtonBuy(provider: provider)
            self?.interactor.userDidRequestOnramp(provider: provider)
        }

        return viewModel
    }

    func mapToRecommendedOnrampOfferViewModel(provider: OnrampProvider) -> OnrampOfferViewModel {
        let title = onrampOfferViewModelBuilder.mapToOnrampOfferViewModelTitle(provider: provider)
        let viewModel = onrampOfferViewModelBuilder.mapToOnrampOfferViewModel(provider: provider) { [weak self] in
            switch title {
            case .bestRate: self?.analyticsLogger.logOnrampBestRateClicked(provider: provider)
            case .fastest: self?.analyticsLogger.logOnrampFastestMethodClicked(provider: provider)
            case .text: break
            }

            self?.analyticsLogger.logOnrampOfferButtonBuy(provider: provider)
            self?.interactor.userDidRequestOnramp(provider: provider)
        }

        return viewModel
    }

    func updateViewState(isLoading: Bool) {
        if suggestedOffersIsVisible, isLoading {
            suggestedOffersIsVisible = false
        }
    }
}

// MARK: - SendStepViewAnimatable

extension NewOnrampViewModel: SendStepViewAnimatable {
    func viewDidChangeVisibilityState(_ state: SendStepVisibilityState) {}
}

// MARK: - SendStepViewAnimatable

extension NewOnrampViewModel {
    enum ViewState: Hashable {
        case presets([FiatPresetService.Preset])
        case continueButton
        case suggestedOffers(SuggestedOffers)
    }

    struct SuggestedOffers: Hashable {
        let recent: OnrampOfferViewModel?
        let recommended: [OnrampOfferViewModel]
        let shouldShowAllOffersButton: Bool
    }
}

struct FiatPresetService {
    @Injected(\.onrampRepository)
    private var onrampRepository: OnrampRepository

    private let amounts: [Decimal] = [50, 100, 200, 300, 500]
    private let balanceFormatter = BalanceFormatter()

    func presets() -> [Preset]? {
        switch onrampRepository.preferenceCurrency?.identity.code {
        case "USD":
            return makePresets(for: "USD")
        case "EUR":
            return makePresets(for: "EUR")
        default:
            return nil
        }
    }

    private func makePresets(for currencyCode: String) -> [Preset] {
        return amounts.map { amount in
            let formatted = balanceFormatter.formatFiatBalance(amount, currencyCode: currencyCode, formattingOptions: .init(
                minFractionDigits: 0,
                maxFractionDigits: 0,
                formatEpsilonAsLowestRepresentableValue: true,
                roundingType: .default(roundingMode: .plain, scale: 0)
            ))
            return Preset(amount: amount, formatted: formatted)
        }
    }

    struct Preset: Hashable, Identifiable {
        var id: Int { hashValue }

        let amount: Decimal
        let formatted: String
    }
}
