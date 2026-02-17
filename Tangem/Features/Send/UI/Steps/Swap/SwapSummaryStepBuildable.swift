//
//  SwapSummaryStepBuildable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol SwapSummaryStepBuildable {
    var summaryIO: SwapSummaryStepBuilder.IO { get }
    var summaryTypes: SwapSummaryStepBuilder.Types { get }
    var summaryDependencies: SwapSummaryStepBuilder.Dependencies { get }
}

extension SwapSummaryStepBuildable {
    func makeSwapSummaryStep(feeCompactViewModel: SendFeeCompactViewModel) -> SwapSummaryStepBuilder.ReturnValue {
        SwapSummaryStepBuilder.make(
            io: summaryIO,
            types: summaryTypes,
            dependencies: summaryDependencies,
            feeCompactViewModel: feeCompactViewModel
        )
    }
}

enum SwapSummaryStepBuilder {
    struct IO {
        let input: SendSummaryInput
        let output: SendSummaryOutput
        let sourceTokenInput: SendSourceTokenInput
        let sourceTokenAmountInput: SendSourceTokenAmountInput
        let receiveTokenInput: SendReceiveTokenInput
        let receiveTokenAmountInput: SendReceiveTokenAmountInput
    }

    struct Types {
        let initialSourceToken: SendSourceToken
    }

    struct Dependencies {
        let notificationManager: any NotificationManager
        let analyticsLogger: any SendSummaryAnalyticsLogger
        let sendDescriptionBuilder: any SendTransactionSummaryDescriptionBuilder
        let swapDescriptionBuilder: any SwapTransactionSummaryDescriptionBuilder
        let stakingDescriptionBuilder: any StakingTransactionSummaryDescriptionBuilder
    }

    typealias ReturnValue = SwapSummaryStep

    static func make(
        io: IO,
        types: Types,
        dependencies: Dependencies,
        feeCompactViewModel: SendFeeCompactViewModel,
    ) -> ReturnValue {
        let interactor = CommonSwapSummaryInteractor(
            input: io.input,
            output: io.output,
            receiveTokenAmountInput: io.receiveTokenAmountInput,
            sendDescriptionBuilder: dependencies.sendDescriptionBuilder,
            swapDescriptionBuilder: dependencies.swapDescriptionBuilder,
            stakingDescriptionBuilder: dependencies.stakingDescriptionBuilder,
        )

        let swapAmountViewModel = SwapAmountViewModel(
            initialSourceToken: types.initialSourceToken,
            sourceTokenInput: io.sourceTokenInput,
            sourceTokenAmountInput: io.sourceTokenAmountInput,
            receiveTokenInput: io.receiveTokenInput,
            receiveTokenAmountInput: io.receiveTokenAmountInput
        )

        let viewModel = SwapSummaryViewModel(
            interactor: interactor,
            notificationManager: dependencies.notificationManager,
            analyticsLogger: dependencies.analyticsLogger,
            swapAmountViewModel: swapAmountViewModel,
            feeCompactViewModel: feeCompactViewModel,
        )

        swapAmountViewModel.router = viewModel

        let step = SwapSummaryStep(
            viewModel: viewModel,
            interactor: interactor,
            analyticsLogger: dependencies.analyticsLogger
        )

        return step
    }
}
