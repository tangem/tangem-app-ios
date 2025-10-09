//
//  OnrampProvidersBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

struct OnrampProvidersBuilder {
    typealias IO = (input: OnrampProvidersInput, output: OnrampProvidersOutput)
    typealias ReturnValue = OnrampProvidersViewModel

    private let io: IO
    private let tokenItem: TokenItem
    private let paymentMethodsInput: OnrampPaymentMethodsInput
    private let analyticsLogger: SendOnrampProvidersAnalyticsLogger

    init(
        io: IO,
        tokenItem: TokenItem,
        paymentMethodsInput: OnrampPaymentMethodsInput,
        analyticsLogger: SendOnrampProvidersAnalyticsLogger
    ) {
        self.io = io
        self.tokenItem = tokenItem
        self.paymentMethodsInput = paymentMethodsInput
        self.analyticsLogger = analyticsLogger
    }

    func makeOnrampProvidersViewModel(coordinator: any OnrampProvidersRoutable) -> ReturnValue {
        let interactor = makeOnrampProvidersInteractor(io: io)
        let viewModel = OnrampProvidersViewModel(
            tokenItem: tokenItem,
            interactor: interactor,
            analyticsLogger: analyticsLogger,
            coordinator: coordinator
        )

        return viewModel
    }

    func makeOnrampProvidersCompactViewModel() -> OnrampProvidersCompactViewModel {
        OnrampProvidersCompactViewModel(providersInput: io.input)
    }
}

// MARK: - Private

private extension OnrampProvidersBuilder {
    func makeOnrampProvidersInteractor(io: IO) -> OnrampProvidersInteractor {
        CommonOnrampProvidersInteractor(
            input: io.input,
            output: io.output,
            paymentMethodsInput: paymentMethodsInput
        )
    }
}
