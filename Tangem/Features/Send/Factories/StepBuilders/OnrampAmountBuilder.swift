//
//  OnrampAmountBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

struct OnrampAmountBuilder {
    typealias IO = (input: OnrampAmountInput, output: OnrampAmountOutput)
    typealias ReturnValue = (viewModel: OnrampAmountViewModel, interactor: OnrampAmountInteractor)
    typealias NewReturnValue = (viewModel: NewOnrampAmountViewModel, interactor: OnrampAmountInteractor)

    private let walletModel: any WalletModel
    private let builder: SendDependenciesBuilder

    init(walletModel: any WalletModel, builder: SendDependenciesBuilder) {
        self.walletModel = walletModel
        self.builder = builder
    }

    func makeOnrampAmountViewModel(io: IO, onrampProvidersInput: OnrampProvidersInput, coordinator: OnrampAmountRoutable) -> ReturnValue {
        let interactor = CommonOnrampAmountInteractor(
            input: io.input,
            output: io.output,
            onrampProvidersInput: onrampProvidersInput
        )

        let viewModel = OnrampAmountViewModel(
            tokenItem: walletModel.tokenItem,
            initialAmount: io.input.amount,
            interactor: interactor,
            coordinator: coordinator
        )

        return (viewModel: viewModel, interactor: interactor)
    }

    func makeNewOnrampAmountViewModel(io: IO, onrampProvidersInput: OnrampProvidersInput, coordinator: OnrampAmountRoutable) -> NewReturnValue {
        let interactor = CommonOnrampAmountInteractor(
            input: io.input,
            output: io.output,
            onrampProvidersInput: onrampProvidersInput
        )

        let viewModel = NewOnrampAmountViewModel(
            tokenItem: walletModel.tokenItem,
            initialAmount: io.input.amount,
            interactor: interactor,
            coordinator: coordinator
        )

        return (viewModel: viewModel, interactor: interactor)
    }

    func makeOnrampAmountCompactViewModel(
        onrampAmountInput: OnrampAmountInput,
        onrampProvidersInput: OnrampProvidersInput
    ) -> OnrampAmountCompactViewModel {
        OnrampAmountCompactViewModel(
            onrampAmountInput: onrampAmountInput,
            onrampProvidersInput: onrampProvidersInput,
            tokenItem: walletModel.tokenItem
        )
    }
}
