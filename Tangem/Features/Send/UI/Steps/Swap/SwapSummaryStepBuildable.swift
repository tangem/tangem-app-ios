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
        dependencies: Dependencies,
        swapAmountViewModel: SwapAmountViewModel,
        swapSummaryProviderViewModel: SwapSummaryProviderViewModel,
        feeCompactViewModel: SendFeeCompactViewModel,
    ) -> ReturnValue {
        let interactor = CommonSwapSummaryInteractor(
            input: io.input,
            output: io.output,
            receiveTokenAmountInput: io.receiveTokenAmountInput,
            swapDescriptionBuilder: dependencies.swapDescriptionBuilder,
        )

        let viewModel = SwapSummaryViewModel(
            interactor: interactor,
            notificationManager: dependencies.notificationManager,
            analyticsLogger: dependencies.analyticsLogger,
            swapAmountViewModel: swapAmountViewModel,
            swapSummaryProviderViewModel: swapSummaryProviderViewModel,
            feeCompactViewModel: feeCompactViewModel,
        )

        swapAmountViewModel.router = viewModel
        swapSummaryProviderViewModel.router = viewModel

        let step = SwapSummaryStep(
            viewModel: viewModel,
            interactor: interactor,
            analyticsLogger: dependencies.analyticsLogger
        )

        return step
    }
}
