//
//  OnrampSummaryStepBuildable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

protocol OnrampSummaryStepBuildable {
    var onrampIO: OnrampSummaryStepBuilder.IO { get }
    var onrampTypes: OnrampSummaryStepBuilder.Types { get }
    var onrampDependencies: OnrampSummaryStepBuilder.Dependencies { get }
}

extension OnrampSummaryStepBuildable {
    func makeOnrampSummaryStep() -> OnrampSummaryStepBuilder.ReturnValue {
        OnrampSummaryStepBuilder.make(
            io: onrampIO, types: onrampTypes, dependencies: onrampDependencies
        )
    }
}

enum OnrampSummaryStepBuilder {
    struct IO {
        let amountInput: any OnrampAmountInput
        let amountOutput: any OnrampAmountOutput
        let output: any OnrampSummaryOutput

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

    typealias ReturnValue = OnrampSummaryStep

    static func make(io: IO, types: Types, dependencies: Dependencies) -> ReturnValue {
        let interactor = CommonOnrampSummaryInteractor(
            amountInput: io.amountInput,
            amountOutput: io.amountOutput,
            providersInput: io.providersInput,
            recentFinder: io.recentOnrampTransactionParametersFinder,
            output: io.output
        )

        let onrampAmountViewModel = OnrampAmountViewModel(
            tokenItem: types.tokenItem,
            initialAmount: io.amountInput.amount,
            interactor: interactor
        )

        let viewModel = OnrampSummaryViewModel(
            onrampAmountViewModel: onrampAmountViewModel,
            tokenItem: types.tokenItem,
            interactor: interactor,
            notificationManager: dependencies.notificationManager,
            analyticsLogger: dependencies.analyticsLogger
        )

        let step = OnrampSummaryStep(tokenItem: types.tokenItem, viewModel: viewModel, interactor: interactor)

        return step
    }
}
