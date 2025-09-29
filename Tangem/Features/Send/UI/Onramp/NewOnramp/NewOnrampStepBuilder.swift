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
        notificationManager: some NotificationManager,
        analyticsLogger: some SendOnrampOffersAnalyticsLogger
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
            notificationManager: notificationManager,
            analyticsLogger: analyticsLogger
        )
        let step = NewOnrampStep(tokenItem: walletModel.tokenItem, viewModel: viewModel, interactor: interactor)

        return (step: step, interactor: interactor)
    }
}

protocol NewOnrampStepBuildable {
    var onrampIO: NewOnrampStepBuilder2.IO { get }
    var onrampTypes: NewOnrampStepBuilder2.Types { get }
    var onrampDependencies: NewOnrampStepBuilder2.Dependencies { get }
}

extension NewOnrampStepBuildable {
    func makeOnrampStep(router: OnrampAmountRoutable) -> NewOnrampStepBuilder2.ReturnValue {
        NewOnrampStepBuilder2.make(
            io: onrampIO,
            types: onrampTypes,
            dependencies: onrampDependencies,
            router: router
        )
    }
}

enum NewOnrampStepBuilder2 {
    struct IO {
        let input: any OnrampInput
        let output: any OnrampOutput

        let amountInput: any OnrampAmountInput
        let amountOutput: any OnrampAmountOutput

        let providersInput: any OnrampProvidersInput
        let recentOnrampProviderFinder: any RecentOnrampProviderFinder
    }

    struct Types {
        let tokenItem: TokenItem
    }

    struct Dependencies {
        let notificationManager: any NotificationManager
        let analyticsLogger: any SendOnrampOffersAnalyticsLogger
    }

    typealias ReturnValue = NewOnrampStep

    static func make(io: IO, types: Types, dependencies: Dependencies, router: OnrampAmountRoutable) -> ReturnValue {
        let interactor = CommonNewOnrampInteractor(
            input: io.input,
            output: io.output,
            providersInput: io.providersInput,
            recentOnrampProviderFinder: io.recentOnrampProviderFinder
        )

        let onrampAmountViewModel = makeNewOnrampAmountViewModel(io: io, types: types, router: router)

        let viewModel = NewOnrampViewModel(
            onrampAmountViewModel: onrampAmountViewModel,
            tokenItem: types.tokenItem,
            interactor: interactor,
            notificationManager: dependencies.notificationManager,
            analyticsLogger: dependencies.analyticsLogger
        )

        let step = NewOnrampStep(tokenItem: types.tokenItem, viewModel: viewModel, interactor: interactor)

        return step
    }

    static func makeNewOnrampAmountViewModel(io: IO, types: Types, router: OnrampAmountRoutable) -> NewOnrampAmountViewModel {
        let interactor = CommonOnrampAmountInteractor(
            input: io.amountInput,
            output: io.amountOutput,
            onrampProvidersInput: io.providersInput
        )

        let viewModel = NewOnrampAmountViewModel(
            tokenItem: types.tokenItem,
            initialAmount: io.amountInput.amount,
            interactor: interactor,
            coordinator: router
        )

        return viewModel
    }
}
