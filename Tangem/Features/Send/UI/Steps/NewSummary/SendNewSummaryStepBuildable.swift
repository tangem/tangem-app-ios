//
//  SendNewSummaryStepBuildable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol SendNewSummaryStepBuildable {
    var newSummaryIO: SendNewSummaryStepBuilder.IO { get }
    var newSummaryTypes: SendNewSummaryStepBuilder.Types { get }
    var newSummaryDependencies: SendNewSummaryStepBuilder.Dependencies { get }
}

extension SendNewSummaryStepBuildable {
    func makeSendNewSummaryStep(
        sendDestinationCompactViewModel: SendDestinationCompactViewModel? = nil,
        sendAmountCompactViewModel: SendNewAmountCompactViewModel? = nil,
        nftAssetCompactViewModel: NFTAssetCompactViewModel? = nil,
        stakingValidatorsCompactViewModel: StakingValidatorsCompactViewModel? = nil,
        sendFeeCompactViewModel: SendNewFeeCompactViewModel? = nil
    ) -> SendNewSummaryStepBuilder.ReturnValue {
        SendNewSummaryStepBuilder.make(
            io: newSummaryIO,
            types: newSummaryTypes,
            dependencies: newSummaryDependencies,
            sendDestinationCompactViewModel: sendDestinationCompactViewModel,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            nftAssetCompactViewModel: nftAssetCompactViewModel,
            stakingValidatorsCompactViewModel: stakingValidatorsCompactViewModel,
            sendFeeCompactViewModel: sendFeeCompactViewModel,
        )
    }
}

enum SendNewSummaryStepBuilder {
    struct IO {
        let input: SendSummaryInput
        let output: SendSummaryOutput
        let receiveTokenAmountInput: SendReceiveTokenAmountInput
    }

    struct Types {
        let settings: SendNewSummaryViewModel.Settings
    }

    struct Dependencies {
        let sendFeeProvider: any SendFeeProvider
        let notificationManager: any NotificationManager
        let analyticsLogger: any SendSummaryAnalyticsLogger
        let sendDescriptionBuilder: any SendTransactionSummaryDescriptionBuilder
        let swapDescriptionBuilder: any SwapTransactionSummaryDescriptionBuilder
    }

    typealias ReturnValue = SendNewSummaryStep

    static func make(
        io: IO,
        types: Types,
        dependencies: Dependencies,
        sendDestinationCompactViewModel: SendDestinationCompactViewModel?,
        sendAmountCompactViewModel: SendNewAmountCompactViewModel?,
        nftAssetCompactViewModel: NFTAssetCompactViewModel?,
        stakingValidatorsCompactViewModel: StakingValidatorsCompactViewModel?,
        sendFeeCompactViewModel: SendNewFeeCompactViewModel?
    ) -> ReturnValue {
        let interactor = CommonSendNewSummaryInteractor(
            input: io.input,
            output: io.output,
            receiveTokenAmountInput: io.receiveTokenAmountInput,
            sendDescriptionBuilder: dependencies.sendDescriptionBuilder,
            swapDescriptionBuilder: dependencies.swapDescriptionBuilder
        )

        let viewModel = SendNewSummaryViewModel(
            interactor: interactor,
            settings: types.settings,
            notificationManager: dependencies.notificationManager,
            analyticsLogger: dependencies.analyticsLogger,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            nftAssetCompactViewModel: nftAssetCompactViewModel,
            sendDestinationCompactViewModel: sendDestinationCompactViewModel,
            stakingValidatorsCompactViewModel: stakingValidatorsCompactViewModel,
            sendFeeCompactViewModel: sendFeeCompactViewModel
        )

        let step = SendNewSummaryStep(
            viewModel: viewModel,
            interactor: interactor,
            analyticsLogger: dependencies.analyticsLogger,
            sendFeeProvider: dependencies.sendFeeProvider
        )

        return step
    }
}
