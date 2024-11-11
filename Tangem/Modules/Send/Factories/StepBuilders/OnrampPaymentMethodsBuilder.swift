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
    private let dataRepository: OnrampDataRepository

    init(io: IO, dataRepository: OnrampDataRepository) {
        self.io = io
        self.dataRepository = dataRepository
    }

    func makeOnrampPaymentMethodsViewModel(coordinator: any OnrampPaymentMethodsRoutable) -> ReturnValue {
        let interactor = makeOnrampPaymentMethodsInteractor(io: io)
        let viewModel = OnrampPaymentMethodsViewModel(interactor: interactor, dataRepository: dataRepository, coordinator: coordinator)

        return viewModel
    }
}

// MARK: - Private

private extension OnrampPaymentMethodsBuilder {
    func makeOnrampPaymentMethodsInteractor(io: IO) -> OnrampPaymentMethodsInteractor {
        CommonOnrampPaymentMethodsInteractor(
            input: io.input,
            output: io.output
        )
    }
}
