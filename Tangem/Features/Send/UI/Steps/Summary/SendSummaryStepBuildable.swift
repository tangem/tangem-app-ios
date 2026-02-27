//
//  SendSummaryStepBuildable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol SendSummaryStepBuildable {
    var summaryIO: SendSummaryStepBuilder.IO { get }
    var summaryTypes: SendSummaryStepBuilder.Types { get }
    var summaryDependencies: SendSummaryStepBuilder.Dependencies { get }
}

extension SendSummaryStepBuildable {
    func makeSendSummaryStep(
        sendDestinationCompactViewModel: SendDestinationCompactViewModel? = nil,
        sendAmountCompactViewModel: SendAmountCompactViewModel? = nil,
        nftAssetCompactViewModel: NFTAssetCompactViewModel? = nil,
        stakingTargetsCompactViewModel: StakingTargetsCompactViewModel? = nil,
        sendFeeCompactViewModel: SendFeeCompactViewModel? = nil
    ) -> SendSummaryStepBuilder.ReturnValue {
        SendSummaryStepBuilder.make(
            io: summaryIO,
            types: summaryTypes,
            dependencies: summaryDependencies,
            sendDestinationCompactViewModel: sendDestinationCompactViewModel,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            nftAssetCompactViewModel: nftAssetCompactViewModel,
            stakingTargetsCompactViewModel: stakingTargetsCompactViewModel,
            sendFeeCompactViewModel: sendFeeCompactViewModel,
        )
    }
}

enum SendSummaryStepBuilder {
    struct IO {
        let input: SendSummaryInput
        let output: SendSummaryOutput
        let swapModelStateProvider: SwapModelStateProvider?

        init(
            input: SendSummaryInput,
            output: SendSummaryOutput,
            swapModelStateProvider: SwapModelStateProvider? = nil
        ) {
            self.input = input
            self.output = output
            self.swapModelStateProvider = swapModelStateProvider
        }
    }

    struct Types {
        let settings: SendSummaryViewModel.Settings
    }

    struct Dependencies {
        let sendFeeProvider: any SendFeeUpdater
        let notificationManager: any NotificationManager
        let analyticsLogger: any SendSummaryAnalyticsLogger
        let sendDescriptionBuilder: any SendTransactionSummaryDescriptionBuilder
        let sendWithSwapDescriptionBuilder: any SendWithSwapTransactionSummaryDescriptionBuilder
        let stakingDescriptionBuilder: any StakingTransactionSummaryDescriptionBuilder
    }

    typealias ReturnValue = SendSummaryStep

    static func make(
        io: IO,
        types: Types,
        dependencies: Dependencies,
        sendDestinationCompactViewModel: SendDestinationCompactViewModel?,
        sendAmountCompactViewModel: SendAmountCompactViewModel?,
        nftAssetCompactViewModel: NFTAssetCompactViewModel?,
        stakingTargetsCompactViewModel: StakingTargetsCompactViewModel?,
        sendFeeCompactViewModel: SendFeeCompactViewModel?
    ) -> ReturnValue {
        let interactor = CommonSendSummaryInteractor(
            input: io.input,
            output: io.output,
            swapModelStateProvider: io.swapModelStateProvider,
            sendDescriptionBuilder: dependencies.sendDescriptionBuilder,
            sendWithSwapDescriptionBuilder: dependencies.sendWithSwapDescriptionBuilder,
            stakingDescriptionBuilder: dependencies.stakingDescriptionBuilder,
        )

        let viewModel = SendSummaryViewModel(
            interactor: interactor,
            settings: types.settings,
            notificationManager: dependencies.notificationManager,
            analyticsLogger: dependencies.analyticsLogger,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            nftAssetCompactViewModel: nftAssetCompactViewModel,
            sendDestinationCompactViewModel: sendDestinationCompactViewModel,
            stakingTargetsCompactViewModel: stakingTargetsCompactViewModel,
            sendFeeCompactViewModel: sendFeeCompactViewModel
        )

        let step = SendSummaryStep(
            viewModel: viewModel,
            interactor: interactor,
            analyticsLogger: dependencies.analyticsLogger,
            sendFeeProvider: dependencies.sendFeeProvider
        )

        return step
    }
}
