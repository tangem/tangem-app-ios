//
//  OnrampSummaryInteractor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress
import TangemFoundation

protocol OnrampSummaryInteractor: AnyObject {
    var currencyPublisher: AnyPublisher<OnrampFiatCurrency?, Never> { get }
    var bottomInfoPublisher: AnyPublisher<LoadingResult<Decimal, OnrampSummaryInteractorBottomInfoError>?, Never> { get }

    var suggestedOffersPublisher: AnyPublisher<LoadingResult<OnrampSummaryInteractorSuggestedOffer?, Never>, Never> { get }
    var isLoadingPublisher: AnyPublisher<Bool, Never> { get }

    func userDidChangeFiat(amount: Decimal?)
    func userDidRequestOnramp(provider: OnrampProvider)
}

enum OnrampSummaryInteractorBottomInfoError: Error {
    case noAvailableProviders
    case tooSmallAmount(_ minAmount: String)
    case tooBigAmount(_ maxAmount: String)
}

class CommonOnrampSummaryInteractor {
    private weak var amountInput: OnrampAmountInput?
    private weak var amountOutput: OnrampAmountOutput?
    private weak var providersInput: OnrampProvidersInput?
    private weak var recentFinder: RecentOnrampTransactionParametersFinder?

    private weak var output: OnrampSummaryOutput?

    init(
        amountInput: any OnrampAmountInput,
        amountOutput: any OnrampAmountOutput,
        providersInput: any OnrampProvidersInput,
        recentFinder: any RecentOnrampTransactionParametersFinder,
        output: any OnrampSummaryOutput,
    ) {
        self.amountInput = amountInput
        self.amountOutput = amountOutput
        self.providersInput = providersInput
        self.recentFinder = recentFinder
        self.output = output
    }
}

// MARK: - OnrampSummaryInteractor

extension CommonOnrampSummaryInteractor: OnrampSummaryInteractor {
    var currencyPublisher: AnyPublisher<OnrampFiatCurrency?, Never> {
        guard let amountInput else {
            assertionFailure("OnrampAmountInput not found")
            return Empty().eraseToAnyPublisher()
        }

        return amountInput.fiatCurrencyPublisher.eraseToAnyPublisher()
    }

    var bottomInfoPublisher: AnyPublisher<LoadingResult<Decimal, OnrampSummaryInteractorBottomInfoError>?, Never> {
        guard let providersInput else {
            assertionFailure("OnrampProvidersInput not found")
            return Empty().eraseToAnyPublisher()
        }

        let hasProviders = providersInput
            .onrampProvidersPublisher
            .map { providers in
                switch providers {
                case .none, .loading, .failure:
                    return false
                case .success(let providers):
                    return !providers.hasProviders()
                }
            }

        return Publishers
            .CombineLatest(hasProviders, providersInput.selectedOnrampProviderPublisher)
            .map { hasProviders, provider -> LoadingResult<Decimal, OnrampSummaryInteractorBottomInfoError>? in
                guard !hasProviders else {
                    return .failure(.noAvailableProviders)
                }

                switch (provider, provider?.value?.state) {
                case (_, .restriction(.tooSmallAmount(_, let formatted))):
                    return .failure(.tooSmallAmount(formatted))
                case (_, .restriction(.tooBigAmount(_, let formatted))):
                    return .failure(.tooBigAmount(formatted))
                case (.none, _), (_, .idle):
                    return .success(0) // placeholder
                case (.loading, _), (_, .loading):
                    return .loading
                case (_, .loaded(let quote)):
                    return .success(quote.expectedAmount)
                case (_, .failed), (_, .notSupported), (_, .none):
                    return nil
                }
            }
            .eraseToAnyPublisher()
    }

    var suggestedOffersPublisher: AnyPublisher<LoadingResult<OnrampSummaryInteractorSuggestedOffer?, Never>, Never> {
        guard let providersInput else {
            assertionFailure("OnrampProvidersInput not found")
            return Empty().eraseToAnyPublisher()
        }

        return Publishers.CombineLatest(
            providersInput.selectedOnrampProviderPublisher,
            providersInput.onrampProvidersPublisher,
        )
        .withWeakCaptureOf(self)
        .map { $0.mapToSuggestedOffers(selectedProvider: $1.0, providers: $1.1) }
        .eraseToAnyPublisher()
    }

    var isLoadingPublisher: AnyPublisher<Bool, Never> {
        guard let providersInput else {
            assertionFailure("OnrampProvidersInput not found")
            return Empty().eraseToAnyPublisher()
        }

        return Publishers.CombineLatest(
            providersInput.selectedOnrampProviderPublisher.map { $0?.isLoading ?? false },
            providersInput.onrampProvidersPublisher.map { $0?.isLoading ?? false }
        )
        .map { $0 || $1 }
        .eraseToAnyPublisher()
    }

    func userDidRequestOnramp(provider: OnrampProvider) {
        output?.userDidRequestOnramp(provider: provider)
    }

    func userDidChangeFiat(amount: Decimal?) {
        guard let amount, amount > 0 else {
            // Field is empty or zero
            amountOutput?.userDidChangedFiat(amount: .none)
            return
        }

        amountOutput?.userDidChangedFiat(amount: amount)
    }
}

// MARK: - Private

private extension CommonOnrampSummaryInteractor {
    func mapToSuggestedOffers(
        selectedProvider: LoadingResult<OnrampProvider, Never>?,
        providers: LoadingResult<ProvidersList, Error>?
    ) -> LoadingResult<OnrampSummaryInteractorSuggestedOffer?, Never> {
        switch (selectedProvider, providers) {
        case (.none, _), (_, .none), (.failure, _), (_, .failure):
            return .success(.none)
        case (.loading, _), (_, .loading):
            return .loading
        case (.success, .success(let list)):
            let recent: OnrampProvider? = {
                guard let recentOnrampTransaction = recentFinder?.recentOnrampTransaction else {
                    return nil
                }

                let allProviders = list.flatMap { $0.providers }.sorted()
                let recent = allProviders.first(where: { provider in
                    let sameProvider = provider.provider.id == recentOnrampTransaction.providerId
                    let samePaymentMethod = provider.paymentMethod.id == recentOnrampTransaction.paymentMethodId

                    return sameProvider && samePaymentMethod && provider.isSuccessfullyLoaded
                })

                return recent
            }()

            let great = list.great() ?? list.best()
            let fastest = list.fastest()
            let successfullyLoadedProviders = list.successfullyLoadedProviders()

            let recommended: [OnrampProvider] = {
                switch recent {
                // When we don't have a provider with badge
                // We have to recommend at least one
                case .none where fastest == .none && great == .none:
                    return successfullyLoadedProviders.first.map { [$0] } ?? []
                case .some(let recent) where recent == fastest && recent == great:
                    return []
                case let recent where recent == great:
                    return [fastest].compactMap(\.self).filter(\.isSuccessfullyLoaded)
                case let recent where recent == fastest:
                    return [great].compactMap(\.self).filter(\.isSuccessfullyLoaded)
                case .none, .some:
                    return [great, fastest].compactMap(\.self).filter(\.isSuccessfullyLoaded).unique()
                }
            }()

            let suggested = ([recent] + recommended).compactMap(\.self).filter(\.isSuccessfullyLoaded).toSet()

            guard !suggested.isEmpty else {
                return .success(.none)
            }

            let suggestedOffers = OnrampSummaryInteractorSuggestedOffer(
                recent: recent,
                recommended: recommended
            )

            return .success(suggestedOffers)
        }
    }
}

struct OnrampSummaryInteractorSuggestedOffer: Hashable {
    let recent: OnrampProvider?
    let recommended: [OnrampProvider]
}

protocol RecentOnrampTransactionParametersFinder: AnyObject {
    var recentOnrampTransaction: RecentOnrampTransactionParameters? { get }
}

struct RecentOnrampTransactionParameters {
    let providerId: String
    let paymentMethodId: String
}
