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

        return .amount
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

    private lazy var onrampOfferViewModelBuilder = OnrampOfferViewModelBuilder(tokenItem: tokenItem)

    private var bag: Set<AnyCancellable> = []

    init(
        onrampAmountViewModel: NewOnrampAmountViewModel,
        tokenItem: TokenItem,
        interactor: NewOnrampInteractor,
        notificationManager: NotificationManager
    ) {
        self.onrampAmountViewModel = onrampAmountViewModel
        self.tokenItem = tokenItem
        self.interactor = interactor
        self.notificationManager = notificationManager

        bind()
    }

    func usedDidTapContinue() {
        shouldShowLegalText = false
        suggestedOffersIsVisible = true
    }

    func openOnrampSettingsView() {
        router?.openOnrampSettingsView()
    }

    func userDidTapAllOffersButton() {
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
                recent: offers.recent.map { mapToOnrampOfferViewModel(provider: $0) },
                recommended: offers.recommended.map { mapToOnrampOfferViewModel(provider: $0) },
                shouldShowAllOffersButton: offers.shouldShowAllOffersButton
            )
        }
    }

    func mapToOnrampOfferViewModel(provider: OnrampProvider) -> OnrampOfferViewModel {
        onrampOfferViewModelBuilder.mapToOnrampOfferViewModel(provider: provider) { [weak self] in
            self?.interactor.userDidRequestOnramp(provider: provider)
        }
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
        case amount
        case suggestedOffers(SuggestedOffers)
    }

    struct SuggestedOffers: Hashable {
        let recent: OnrampOfferViewModel?
        let recommended: [OnrampOfferViewModel]
        let shouldShowAllOffersButton: Bool
    }
}
