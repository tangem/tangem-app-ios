//
//  OnrampProvidersCompactViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemExpress
import TangemFoundation

class OnrampProvidersCompactViewModel: ObservableObject {
    @Injected(\.ukGeoDefiner) private var ukGeoDefiner: UKGeoDefiner

    @Published private(set) var paymentState: PaymentState?

    weak var router: OnrampSummaryRoutable?

    private var bag: Set<AnyCancellable> = []

    init(providersInput: OnrampProvidersInput) {
        bind(providersInput: providersInput)
    }

    private func bind(providersInput: OnrampProvidersInput) {
        providersInput
            .selectedOnrampProviderPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] provider in
                self?.updateView(provider: provider)
            }
            .store(in: &bag)
    }

    private func updateView(provider: LoadingResult<OnrampProvider, Never>?) {
        switch (provider, provider?.value?.state) {
        case (.loading, _), (_, .loading):
            paymentState = .loading
        case (.success(let provider), .loaded),
             (.success(let provider), .restriction):
            paymentState = .loaded(
                data: makeOnrampProvidersCompactProviderViewData(provider: provider)
            )
        case (.none, _), (.success, _):
            paymentState = .none
        }
    }

    private func makeOnrampProvidersCompactProviderViewData(provider: OnrampProvider) -> OnrampProvidersCompactProviderViewData {
        let badge: OnrampProvidersCompactProviderViewData.Badge? = switch provider.attractiveType {
        case .none, .loss: .none
        case .best where ukGeoDefiner.isUK: .none
        case .best: .bestRate
        }

        return OnrampProvidersCompactProviderViewData(
            iconURL: provider.paymentMethod.image,
            paymentMethodName: provider.paymentMethod.name,
            providerName: provider.provider.name,
            badge: badge
        ) { [weak self] in
            self?.router?.onrampStepRequestEditProvider()
        }
    }
}

extension OnrampProvidersCompactViewModel {
    enum PaymentState: Hashable, Identifiable {
        case loading
        case loaded(data: OnrampProvidersCompactProviderViewData)

        var id: Int { hashValue }
    }
}
