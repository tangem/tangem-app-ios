//
//  OnrampProvidersInteractor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress

protocol OnrampProvidersInteractor {
    var selectedProviderPublisher: AnyPublisher<OnrampProvider?, Never> { get }
    var providesPublisher: AnyPublisher<[OnrampProvider], Never> { get }

    func update(selectedProvider: OnrampProvider)
}

class CommonOnrampProvidersInteractor {
    private weak var input: OnrampProvidersInput?
    private weak var output: OnrampProvidersOutput?
    private weak var paymentMethodsInput: OnrampPaymentMethodsInput?

    init(
        input: OnrampProvidersInput,
        output: OnrampProvidersOutput,
        paymentMethodsInput: OnrampPaymentMethodsInput
    ) {
        self.input = input
        self.output = output
        self.paymentMethodsInput = paymentMethodsInput
    }
}

// MARK: - OnrampProvidersInteractor

extension CommonOnrampProvidersInteractor: OnrampProvidersInteractor {
    var selectedProviderPublisher: AnyPublisher<OnrampProvider?, Never> {
        guard let input else {
            assertionFailure("OnrampProvidersInput not found")
            return Empty().eraseToAnyPublisher()
        }

        return input
            .selectedOnrampProviderPublisher
            .map { $0?.value }
            .eraseToAnyPublisher()
    }

    var providesPublisher: AnyPublisher<[OnrampProvider], Never> {
        guard let input, let paymentMethodsInput = paymentMethodsInput else {
            assertionFailure("OnrampAmountInput not found")
            return Empty().eraseToAnyPublisher()
        }

        return Publishers
            .CombineLatest(
                input.onrampProvidersPublisher,
                paymentMethodsInput.selectedPaymentMethodPublisher.compactMap { $0 }
            )
            .compactMap { $0?.value?.select(for: $1)?.providers.filter { $0.isShowable } }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func update(selectedProvider: OnrampProvider) {
        output?.userDidSelect(provider: selectedProvider)
    }
}
