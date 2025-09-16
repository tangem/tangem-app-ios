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
    @Published private(set) var viewState: ViewState = .amount

    @Published private(set) var notificationInputs: [NotificationViewInput] = []
    @Published private(set) var notificationButtonIsLoading = false
    @Published private(set) var legalText: AttributedString?

    weak var router: OnrampSummaryRoutable?

    private let tokenItem: TokenItem
    private let interactor: NewOnrampInteractor
    private let notificationManager: NotificationManager

    private let formatter: BalanceFormatter = .init()
    private let percentFormatter: PercentFormatter = .init()

    private var suggestedOffers: SuggestedOffers?
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
        guard let suggestedOffers else {
            return
        }

        viewState = .suggestedOffers(suggestedOffers)
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
            .logging { "suggestedOffersPublisher \($0.mapValue { $0.recommended.count })" }
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { $0.setupOnrampOfferViewModels(offers: $1) }
            .store(in: &bag)

//        interactor
//            .selectedLoadedProviderPublisher
//            .removeDuplicates()
//            .map { $0?.legalText(branch: .onramp) }
//            .receive(on: DispatchQueue.main)
//            .assign(to: \.legalText, on: self, ownership: .weak)
//            .store(in: &bag)
    }

    func setupOnrampOfferViewModels(offers: LoadingResult<OnrampInteractorSuggestedOffer, Never>) {
        switch offers {
        case .loading, .success(.empty):
            suggestedOffers = nil

        case .success(let offers):
            suggestedOffers = .init(
                recent: offers.recent.map { mapToOnrampOfferViewModel(provider: $0) },
                recommended: offers.recommended.map { mapToOnrampOfferViewModel(provider: $0) },
                allOffersButton: offers.allOffersButton
            )
        }
    }

    func mapToOnrampOfferViewModel(provider: OnrampProvider) -> OnrampOfferViewModel {
        let title: OnrampOfferViewModel.Title = switch provider.attractiveType {
        case .best: .bestRate
        default: .text(Localization.onrampTitleYouGet)
        }

        let amount: OnrampOfferViewModel.Amount = {
            let formattedAmount = formatter.formatCryptoBalance(
                provider.quote?.expectedAmount,
                currencyCode: tokenItem.currencySymbol
            )

            switch provider.attractiveType {
            case .best:
                return .init(formatted: formattedAmount, badge: .best)
            case .loss(let percent):
                let formattedPercent = percentFormatter.format(percent, option: .express)
                return .init(formatted: formattedAmount, badge: .loss(percent: formattedPercent, signType: .negative))
            case .none:
                return .init(formatted: formattedAmount, badge: .none)
            }
        }()

        let provider: OnrampOfferViewModel.Provider = .init(
            name: provider.provider.name,
            paymentType: provider.paymentMethod,
            timeFormatted: "1-3 min"
        )

        return OnrampOfferViewModel(
            title: title,
            amount: amount,
            provider: provider
        ) {}
    }

    func updateViewState(isLoading: Bool) {
        switch viewState {
        case .suggestedOffers where isLoading:
            viewState = .amount
        case .amount, .suggestedOffers:
            // Do nothing
            break
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
        static let empty = SuggestedOffers(recent: nil, recommended: [], allOffersButton: false)

        let recent: OnrampOfferViewModel?
        let recommended: [OnrampOfferViewModel]
        let allOffersButton: Bool
    }
}
