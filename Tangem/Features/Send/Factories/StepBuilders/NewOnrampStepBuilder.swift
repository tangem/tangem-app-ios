//
//  NewOnrampStepBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

struct NewOnrampStepBuilder {
    typealias IO = (input: OnrampInput, output: OnrampOutput)
    typealias ReturnValue = (step: NewOnrampStep, interactor: OnrampInteractor)

    private let walletModel: any WalletModel

    init(walletModel: any WalletModel) {
        self.walletModel = walletModel
    }

    func makeOnrampStep(
        io: IO,
        providersInput: some OnrampProvidersInput,
        onrampAmountViewModel: OnrampAmountViewModel,
        onrampProvidersCompactViewModel: OnrampProvidersCompactViewModel,
        notificationManager: some NotificationManager
    ) -> ReturnValue {
        let interactor = CommonOnrampInteractor(input: io.input, output: io.output, providersInput: providersInput)
        let viewModel = NewOnrampViewModel(
            onrampAmountViewModel: onrampAmountViewModel,
            onrampProvidersCompactViewModel: onrampProvidersCompactViewModel,
            notificationManager: notificationManager,
            interactor: interactor
        )

        let step = NewOnrampStep(tokenItem: walletModel.tokenItem, viewModel: viewModel, interactor: interactor)

        return (step: step, interactor: interactor)
    }
}
