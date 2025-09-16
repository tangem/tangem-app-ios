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
            .map { interactor, providers in
                switch providers {
                case .none, .failure: .success(.empty)
                case .loading: .loading
                case .success(let providers): .success(
                        interactor.mapToSuggestedOffers(providers: providers)
                    )
                }
            }
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
    func mapToSuggestedOffers(providers: ProvidersList) -> OnrampInteractorSuggestedOffer {
        let recent: OnrampProvider? = nil
        let best = providers.best()
        let fastest = providers.fastest()

        return .init(
            recent: recent,
            recommended: [best, fastest].compactMap { $0 },
            allOffersButton: providers.hasProviders()
        )
    }
}

struct OnrampInteractorSuggestedOffer: Hashable {
    static let empty = OnrampInteractorSuggestedOffer(recent: nil, recommended: [], allOffersButton: false)

    let recent: OnrampProvider?
    let recommended: [OnrampProvider]
    let allOffersButton: Bool
}
