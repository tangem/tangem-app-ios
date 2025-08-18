//
//  OnrampStepBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

struct OnrampStepBuilder {
    typealias IO = (input: OnrampInput, output: OnrampOutput)
    typealias ReturnValue = (step: OnrampStep, interactor: OnrampInteractor)

    private let tokenItem: TokenItem

    init(tokenItem: TokenItem) {
        self.tokenItem = tokenItem
    }

    func makeOnrampStep(
        io: IO,
        providersInput: some OnrampProvidersInput,
        onrampAmountViewModel: OnrampAmountViewModel,
        onrampProvidersCompactViewModel: OnrampProvidersCompactViewModel,
        notificationManager: some NotificationManager
    ) -> ReturnValue {
        let interactor = makeOnrampInteractor(io: io, providersInput: providersInput)
        let viewModel = makeOnrampViewModel(
            onrampAmountViewModel: onrampAmountViewModel,
            onrampProvidersCompactViewModel: onrampProvidersCompactViewModel,
            notificationManager: notificationManager,
            interactor: interactor
        )
        let step = OnrampStep(tokenItem: tokenItem, viewModel: viewModel, interactor: interactor)

        return (step: step, interactor: interactor)
    }
}

// MARK: - Private

private extension OnrampStepBuilder {
    func makeOnrampViewModel(
        onrampAmountViewModel: OnrampAmountViewModel,
        onrampProvidersCompactViewModel: OnrampProvidersCompactViewModel,
        notificationManager: some NotificationManager,
        interactor: OnrampInteractor
    ) -> OnrampViewModel {
        OnrampViewModel(
            onrampAmountViewModel: onrampAmountViewModel,
            onrampProvidersCompactViewModel: onrampProvidersCompactViewModel,
            notificationManager: notificationManager,
            interactor: interactor
        )
    }

    func makeOnrampInteractor(io: IO, providersInput: some OnrampProvidersInput) -> OnrampInteractor {
        CommonOnrampInteractor(input: io.input, output: io.output, providersInput: providersInput)
    }
}
