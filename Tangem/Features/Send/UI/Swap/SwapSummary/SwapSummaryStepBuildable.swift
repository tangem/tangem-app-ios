//
//  SwapSummaryStepBuildable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol SwapSummaryStepBuildable {
    var summaryIO: SwapSummaryStepBuilder.IO { get }
    var summaryDependencies: SwapSummaryStepBuilder.Dependencies { get }
}

extension SwapSummaryStepBuildable {
    func makeSwapSummaryStep(
        swapAmountViewModel: SwapAmountViewModel,
        swapSummaryProviderViewModel: SwapSummaryProviderViewModel,
        feeCompactViewModel: SendFeeCompactViewModel
    ) -> SwapSummaryStepBuilder.ReturnValue {
        SwapSummaryStepBuilder.make(
            io: summaryIO,
            dependencies: summaryDependencies,
            swapAmountViewModel: swapAmountViewModel,
            swapSummaryProviderViewModel: swapSummaryProviderViewModel,
            feeCompactViewModel: feeCompactViewModel
        )
    }
}

enum SwapSummaryStepBuilder {
    struct IO {
        let input: SwapSummaryInput
        let output: SwapSummaryOutput
        let sourceTokenInput: SendSourceTokenInput
        let sourceTokenAmountInput: SendSourceTokenAmountInput
        let receiveTokenInput: SendReceiveTokenInput
        let receiveTokenAmountInput: SendReceiveTokenAmountInput
        let swapModelStateProvider: SwapModelStateProvider
    }

    struct Dependencies {
        let notificationManager: any NotificationManager
        let autoupdatingTimer: AutoupdatingTimer
        let analyticsLogger: any SendSummaryAnalyticsLogger
        let swapDescriptionBuilder: any SwapTransactionSummaryDescriptionBuilder
    }

    typealias ReturnValue = SwapSummaryStep

    static func make(
        io: IO,
        dependencies: Dependencies,
        swapAmountViewModel: SwapAmountViewModel,
        swapSummaryProviderViewModel: SwapSummaryProviderViewModel,
        feeCompactViewModel: SendFeeCompactViewModel,
    ) -> ReturnValue {
        let interactor = CommonSwapSummaryInteractor(
            input: io.input,
            output: io.output,
            sourceTokenInput: io.sourceTokenInput,
            receiveTokenAmountInput: io.receiveTokenAmountInput,
            swapModelStateProvider: io.swapModelStateProvider,
            swapDescriptionBuilder: dependencies.swapDescriptionBuilder,
        )

        let viewModel = SwapSummaryViewModel(
            interactor: interactor,
            notificationManager: dependencies.notificationManager,
            analyticsLogger: dependencies.analyticsLogger,
            swapAmountViewModel: swapAmountViewModel,
            swapSummaryProviderViewModel: swapSummaryProviderViewModel,
            feeCompactViewModel: feeCompactViewModel,
            sourceTokenInput: io.sourceTokenInput
        )

        swapAmountViewModel.router = viewModel
        swapSummaryProviderViewModel.router = viewModel

        let step = SwapSummaryStep(
            viewModel: viewModel,
            interactor: interactor,
            autoupdatingTimer: dependencies.autoupdatingTimer,
            analyticsLogger: dependencies.analyticsLogger
        )

        return step
    }
}
