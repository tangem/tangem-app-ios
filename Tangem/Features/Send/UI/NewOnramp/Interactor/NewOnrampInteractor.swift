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
    var suggestedOffersPublisher: AnyPublisher<LoadingResult<OnrampInteractorSuggestedOffer, Never>, Never> { get }

    var isLoadingPublisher: AnyPublisher<Bool, Never> { get }
    var isValidPublisher: AnyPublisher<Bool, Never> { get }
}

class CommonNewOnrampInteractor {
    private weak var input: OnrampInput?
    private weak var output: OnrampOutput?
    private weak var providersInput: OnrampProvidersInput?

    init(
        input: OnrampInput,
        output: OnrampOutput,
        providersInput: OnrampProvidersInput
    ) {
        self.input = input
        self.output = output
        self.providersInput = providersInput
    }
}

// MARK: - OnrampInteractor

extension CommonNewOnrampInteractor: NewOnrampInteractor {
    var suggestedOffersPublisher: AnyPublisher<LoadingResult<OnrampInteractorSuggestedOffer, Never>, Never> {
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

    var isValidPublisher: AnyPublisher<Bool, Never> {
        guard let input else {
            assertionFailure("OnrampInput not found")
            return Empty().eraseToAnyPublisher()
        }

        return input.isValidToRedirectPublisher
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
}

// MARK: - Private

private extension CommonNewOnrampInteractor {
    func mapToSuggestedOffers(providers: LoadingResult<ProvidersList, Error>?) -> LoadingResult<OnrampInteractorSuggestedOffer, Never> {
        switch providers {
        case .none, .failure: return .success(.empty)
        case .loading: return .loading
        case .success(let list):
            // [REDACTED_TODO_COMMENT]
            let recent: OnrampProvider? = nil
            let best = list.best()
            let fastest = list.fastest()

            let suggestedOffers = OnrampInteractorSuggestedOffer(
                recent: recent,
                recommended: [best, fastest].compactMap { $0 },
                shouldShowAllOffersButton: list.hasProviders()
            )

            return .success(suggestedOffers)
        }
    }
}

struct OnrampInteractorSuggestedOffer: Hashable {
    static let empty = OnrampInteractorSuggestedOffer(recent: nil, recommended: [], shouldShowAllOffersButton: false)

    let recent: OnrampProvider?
    let recommended: [OnrampProvider]
    let shouldShowAllOffersButton: Bool
}
