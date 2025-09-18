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
    typealias ReturnValue = (step: NewOnrampStep, interactor: NewOnrampInteractor)

    private let walletModel: any WalletModel

    init(walletModel: any WalletModel) {
        self.walletModel = walletModel
    }

    func makeOnrampStep(
        io: IO,
        providersInput: some OnrampProvidersInput,
        recentOnrampProviderFinder: some RecentOnrampProviderFinder,
        onrampAmountViewModel: NewOnrampAmountViewModel,
        onrampProvidersCompactViewModel: OnrampProvidersCompactViewModel,
        notificationManager: some NotificationManager
    ) -> ReturnValue {
        let interactor = CommonNewOnrampInteractor(
            input: io.input,
            output: io.output,
            providersInput: providersInput,
            recentOnrampProviderFinder: recentOnrampProviderFinder
        )
        let viewModel = NewOnrampViewModel(
            onrampAmountViewModel: onrampAmountViewModel,
            tokenItem: walletModel.tokenItem,
            interactor: interactor,
            notificationManager: notificationManager
        )
        let step = NewOnrampStep(tokenItem: walletModel.tokenItem, viewModel: viewModel, interactor: interactor)

        return (step: step, interactor: interactor)
    }
}
