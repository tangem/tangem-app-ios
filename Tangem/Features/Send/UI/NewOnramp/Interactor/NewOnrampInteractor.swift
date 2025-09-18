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

    func userDidRequestOnramp(provider: OnrampProvider)
}

protocol RecentOnrampProviderFinder: AnyObject {
    var recentOnrampProvider: OnrampProvider? { get }
}

class CommonNewOnrampInteractor {
    private weak var input: OnrampInput?
    private weak var output: OnrampOutput?
    private weak var providersInput: OnrampProvidersInput?
    private weak var recentOnrampProviderFinder: RecentOnrampProviderFinder?

    init(
        input: OnrampInput,
        output: OnrampOutput,
        providersInput: OnrampProvidersInput,
        recentOnrampProviderFinder: RecentOnrampProviderFinder
    ) {
        self.input = input
        self.output = output
        self.providersInput = providersInput
        self.recentOnrampProviderFinder = recentOnrampProviderFinder
    }
}

// MARK: - OnrampInteractor

extension CommonNewOnrampInteractor: NewOnrampInteractor {
    var suggestedOffersPublisher: AnyPublisher<LoadingResult<OnrampInteractorSuggestedOffer?, Never>, Never> {
        guard let providersInput else {
            assertionFailure("OnrampProvidersInput not found")
            return Empty().eraseToAnyPublisher()
        }

        return providersInput
            .onrampProvidersPublisher
            .withWeakCaptureOf(self)
            .map { $0.mapToSuggestedOffers(providers: $1) }
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
}

// MARK: - Private

private extension CommonNewOnrampInteractor {
    func mapToSuggestedOffers(providers: LoadingResult<ProvidersList, Error>?) -> LoadingResult<OnrampInteractorSuggestedOffer?, Never> {
        switch providers {
        case .none, .failure: return .success(.none)
        case .loading: return .loading
        case .success(let list):
            let recent: OnrampProvider? = {
                guard let recent = recentOnrampProviderFinder?.recentOnrampProvider,
                      recent.isSuccessfullyLoaded else {
                    return nil
                }

                return recent
            }()

            let best = list.globalBest()
            let fastest = list.fastest()
            let successfullyLoadedProviders = list.successfullyLoadedProviders()

            let recommended: [OnrampProvider] = {
                switch recent {
                case let recent where recent == fastest && recent == best:
                    return []
                case let recent where recent == best:
                    return [fastest].compactMap(\.self).filter(\.isSuccessfullyLoaded)
                case let recent where recent == fastest:
                    return [best].compactMap(\.self).filter(\.isSuccessfullyLoaded)
                case .none, .some:
                    return [best, fastest].compactMap(\.self).filter(\.isSuccessfullyLoaded).unique()
                }
            }()

            let suggested = [recent, best, fastest].compactMap(\.self).filter(\.isSuccessfullyLoaded).toSet()
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
