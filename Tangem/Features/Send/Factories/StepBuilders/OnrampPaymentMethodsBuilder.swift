//
//  OnrampPaymentMethodsBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

struct OnrampPaymentMethodsBuilder {
    typealias IO = (input: OnrampPaymentMethodsInput, output: OnrampPaymentMethodsOutput)
    typealias ReturnValue = OnrampPaymentMethodsViewModel

    private let io: IO
    private let analyticsLogger: SendOnrampPaymentMethodAnalyticsLogger

    init(io: IO, analyticsLogger: SendOnrampPaymentMethodAnalyticsLogger) {
        self.io = io
        self.analyticsLogger = analyticsLogger
    }

    func makeOnrampPaymentMethodsViewModel(coordinator: any OnrampPaymentMethodsRoutable) -> ReturnValue {
        let interactor = CommonOnrampPaymentMethodsInteractor(input: io.input, output: io.output)
        let viewModel = OnrampPaymentMethodsViewModel(interactor: interactor, analyticsLogger: analyticsLogger, coordinator: coordinator)

        return viewModel
    }
}
