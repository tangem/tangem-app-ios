//
//  OnrampPaymentMethodsInteractor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress

protocol OnrampPaymentMethodsInteractor {
    var paymentMethodsPublisher: AnyPublisher<[OnrampPaymentMethod], Never> { get }
    var paymentMethodPublisher: AnyPublisher<OnrampPaymentMethod, Never> { get }

    func update(selectedPaymentMethod: OnrampPaymentMethod)
}

class CommonOnrampPaymentMethodsInteractor {
    private weak var input: OnrampPaymentMethodsInput?
    private weak var output: OnrampPaymentMethodsOutput?

    init(
        input: OnrampPaymentMethodsInput,
        output: OnrampPaymentMethodsOutput
    ) {
        self.input = input
        self.output = output
    }
}

// MARK: - OnrampProvidersInteractor

extension CommonOnrampPaymentMethodsInteractor: OnrampPaymentMethodsInteractor {
    var paymentMethodPublisher: AnyPublisher<OnrampPaymentMethod, Never> {
        guard let input else {
            assertionFailure("OnrampProvidersInput not found")
            return Empty().eraseToAnyPublisher()
        }

        return input
            .selectedPaymentMethodPublisher
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    var paymentMethodsPublisher: AnyPublisher<[OnrampPaymentMethod], Never> {
        guard let input else {
            assertionFailure("OnrampProvidersInput not found")
            return Empty().eraseToAnyPublisher()
        }

        return input
            .paymentMethodsPublisher
            .map { $0.sorted { $0.type.priority > $1.type.priority } }
            .eraseToAnyPublisher()
    }

    func update(selectedPaymentMethod: OnrampPaymentMethod) {
        output?.userDidSelect(paymentMethod: selectedPaymentMethod)
    }
}
