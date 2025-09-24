//
//  SendNewSummaryStepBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct SendNewSummaryStepBuilder {
    typealias IO = (input: SendSummaryInput, output: SendSummaryOutput)
    typealias ReturnValue = SendNewSummaryStep

    let tokenItem: TokenItem
    let builder: SendDependenciesBuilder

    func makeSendSummaryStep(
        io: IO,
        receiveTokenAmountInput: SendReceiveTokenAmountInput,
        sendFeeProvider: SendFeeProvider,
        destinationEditableType: SendSummaryViewModel.EditableType,
        amountEditableType: SendSummaryViewModel.EditableType,
        notificationManager: NotificationManager,
        analyticsLogger: any SendSummaryAnalyticsLogger,
        sendDestinationCompactViewModel: SendDestinationCompactViewModel?,
        sendAmountCompactViewModel: SendNewAmountCompactViewModel?,
        nftAssetCompactViewModel: NFTAssetCompactViewModel?,
        stakingValidatorsCompactViewModel: StakingValidatorsCompactViewModel?,
        sendFeeCompactViewModel: SendNewFeeCompactViewModel?
    ) -> ReturnValue {
        let interactor = makeSendNewSummaryInteractor(
            io: io,
            receiveTokenAmountInput: receiveTokenAmountInput
        )

        let viewModel = SendNewSummaryViewModel(
            interactor: interactor,
            destinationEditableType: destinationEditableType,
            amountEditableType: amountEditableType,
            notificationManager: notificationManager,
            analyticsLogger: analyticsLogger,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            nftAssetCompactViewModel: nftAssetCompactViewModel,
            sendDestinationCompactViewModel: sendDestinationCompactViewModel,
            stakingValidatorsCompactViewModel: stakingValidatorsCompactViewModel,
            sendFeeCompactViewModel: sendFeeCompactViewModel
        )

        let step = SendNewSummaryStep(
            viewModel: viewModel,
            interactor: interactor,
            analyticsLogger: analyticsLogger,
            sendFeeProvider: sendFeeProvider
        )

        return step
    }
}

// MARK: - Private

private extension SendNewSummaryStepBuilder {
    func makeSendNewSummaryInteractor(
        io: IO,
        receiveTokenAmountInput: any SendReceiveTokenAmountInput
    ) -> SendNewSummaryInteractor {
        CommonSendNewSummaryInteractor(
            input: io.input,
            output: io.output,
            receiveTokenAmountInput: receiveTokenAmountInput,
            sendDescriptionBuilder: builder.makeSendTransactionSummaryDescriptionBuilder(),
            swapDescriptionBuilder: builder.makeSwapTransactionSummaryDescriptionBuilder()
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
