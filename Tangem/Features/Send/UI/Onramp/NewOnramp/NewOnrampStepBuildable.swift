//
//  NewOnrampStepBuildable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

protocol NewOnrampStepBuildable {
    var onrampIO: NewOnrampStepBuilder.IO { get }
    var onrampTypes: NewOnrampStepBuilder.Types { get }
    var onrampDependencies: NewOnrampStepBuilder.Dependencies { get }
}

extension NewOnrampStepBuildable {
    func makeOnrampStep(router: OnrampAmountRoutable) -> NewOnrampStepBuilder.ReturnValue {
        NewOnrampStepBuilder.make(
            io: onrampIO,
            types: onrampTypes,
            dependencies: onrampDependencies,
            router: router
        )
    }
}

enum NewOnrampStepBuilder {
    struct IO {
        let input: any OnrampInput
        let output: any OnrampOutput

        let amountInput: any OnrampAmountInput
        let amountOutput: any OnrampAmountOutput

        let providersInput: any OnrampProvidersInput
        let recentOnrampTransactionParametersFinder: any RecentOnrampTransactionParametersFinder
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
            amountOutput: io.amountOutput,
            providersInput: io.providersInput,
            recentFinder: io.recentOnrampTransactionParametersFinder
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
