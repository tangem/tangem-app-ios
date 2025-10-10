//
//  NewOnrampInteractor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress
import TangemFoundation

protocol NewOnrampInteractor: AnyObject {
    var suggestedOffersPublisher: AnyPublisher<LoadingResult<OnrampInteractorSuggestedOffer?, Never>, Never> { get }
    var isLoadingPublisher: AnyPublisher<Bool, Never> { get }

    func update(fiat: Decimal?)
    func userDidRequestOnramp(provider: OnrampProvider)
}

class CommonNewOnrampInteractor {
    private weak var input: OnrampInput?
    private weak var output: OnrampOutput?
    private weak var amountOutput: OnrampAmountOutput?
    private weak var providersInput: OnrampProvidersInput?
    private weak var recentFinder: RecentOnrampTransactionParametersFinder?

    init(
        input: OnrampInput,
        output: OnrampOutput,
        amountOutput: OnrampAmountOutput,
        providersInput: OnrampProvidersInput,
        recentFinder: RecentOnrampTransactionParametersFinder
    ) {
        self.input = input
        self.output = output
        self.amountOutput = amountOutput
        self.providersInput = providersInput
        self.recentFinder = recentFinder
    }
}

// MARK: - OnrampInteractor

extension CommonNewOnrampInteractor: NewOnrampInteractor {
    var suggestedOffersPublisher: AnyPublisher<LoadingResult<OnrampInteractorSuggestedOffer?, Never>, Never> {
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

    func update(fiat: Decimal?) {
        guard let fiat, fiat > 0 else {
            // Field is empty or zero
            amountOutput?.amountDidChanged(fiat: .none)
            return
        }

        amountOutput?.amountDidChanged(fiat: fiat)
    }
}

// MARK: - Private

private extension CommonNewOnrampInteractor {
    func mapToSuggestedOffers(
        selectedProvider: LoadingResult<OnrampProvider, Never>?,
        providers: LoadingResult<ProvidersList, Error>?
    ) -> LoadingResult<OnrampInteractorSuggestedOffer?, Never> {
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
            let hasAnotherProviders = !successfullyLoadedProviders.toSet().subtracting(suggested).isEmpty

            guard !suggested.isEmpty else {
                return .success(.none)
            }

            let suggestedOffers = OnrampInteractorSuggestedOffer(
                recent: recent,
                recommended: recommended,
                shouldShowAllOffersButton: hasAnotherProviders
            )

            return .success(suggestedOffers)
        }
    }
}

struct OnrampInteractorSuggestedOffer: Hashable {
    let recent: OnrampProvider?
    let recommended: [OnrampProvider]
    let shouldShowAllOffersButton: Bool
}

protocol RecentOnrampTransactionParametersFinder: AnyObject {
    var recentOnrampTransaction: RecentOnrampTransactionParameters? { get }
}

struct RecentOnrampTransactionParameters {
    let providerId: String
    let paymentMethodId: String
}
