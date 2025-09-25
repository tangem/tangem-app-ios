//
//  SendNewSummaryStepBuildable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol SendNewSummaryStepBuildable {
    var newSummaryIO: SendNewSummaryStepBuilder2.IO { get }
    var newSummaryDependencies: SendNewSummaryStepBuilder2.Dependencies { get }
}

extension SendNewSummaryStepBuildable {
    func makeSendNewSummaryStep(
        sendDestinationCompactViewModel: SendDestinationCompactViewModel? = nil,
        sendAmountCompactViewModel: SendNewAmountCompactViewModel? = nil,
        nftAssetCompactViewModel: NFTAssetCompactViewModel? = nil,
        stakingValidatorsCompactViewModel: StakingValidatorsCompactViewModel? = nil,
        sendFeeCompactViewModel: SendNewFeeCompactViewModel? = nil
    ) -> SendNewSummaryStepBuilder2.ReturnValue {
        SendNewSummaryStepBuilder2.make(
            io: newSummaryIO,
            dependencies: newSummaryDependencies,
            // [REDACTED_TODO_COMMENT]
            destinationEditableType: .editable,
            amountEditableType: .editable,
            sendDestinationCompactViewModel: sendDestinationCompactViewModel,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            nftAssetCompactViewModel: nftAssetCompactViewModel,
            stakingValidatorsCompactViewModel: stakingValidatorsCompactViewModel,
            sendFeeCompactViewModel: sendFeeCompactViewModel,
        )
    }
}

enum SendNewSummaryStepBuilder2 {
    struct IO {
        let input: SendSummaryInput
        let output: SendSummaryOutput
        let receiveTokenAmountInput: SendReceiveTokenAmountInput
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
        dependencies: Dependencies,
        destinationEditableType: SendSummaryViewModel.EditableType,
        amountEditableType: SendSummaryViewModel.EditableType,
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
            destinationEditableType: destinationEditableType,
            amountEditableType: amountEditableType,
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
