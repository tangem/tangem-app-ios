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
        sendDestinationCompactViewModel: SendNewDestinationCompactViewModel?,
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
