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
    typealias ReturnValue = (step: SendNewSummaryStep, interactor: SendSummaryInteractor)

    let tokenItem: TokenItem
    let builder: SendDependenciesBuilder

    func makeSendSummaryStep(
        io: IO,
        actionType: SendFlowActionType,
        descriptionBuilder: any SendTransactionSummaryDescriptionBuilder,
        notificationManager: NotificationManager,
        feeLoader: SendFeeLoader,
        destinationEditableType: SendSummaryViewModel.EditableType,
        amountEditableType: SendSummaryViewModel.EditableType,
        sendDestinationCompactViewModel: SendNewDestinationCompactViewModel?,
        sendAmountCompactViewModel: SendNewAmountCompactViewModel?,
        sendReceiveTokenCompactViewModel: SendNewAmountCompactViewModel?,
        stakingValidatorsCompactViewModel: StakingValidatorsCompactViewModel?,
        sendFeeCompactViewModel: SendNewFeeCompactViewModel?
    ) -> ReturnValue {
        let interactor = makeSendSummaryInteractor(
            io: io,
            descriptionBuilder: descriptionBuilder
        )

        let viewModel = makeSendSummaryViewModel(
            interactor: interactor,
            actionType: actionType,
            notificationManager: notificationManager,
            destinationEditableType: destinationEditableType,
            amountEditableType: amountEditableType,
            sendDestinationCompactViewModel: sendDestinationCompactViewModel,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            sendReceiveTokenCompactViewModel: sendReceiveTokenCompactViewModel,
            stakingValidatorsCompactViewModel: stakingValidatorsCompactViewModel,
            sendFeeCompactViewModel: sendFeeCompactViewModel
        )

        let step = SendNewSummaryStep(
            viewModel: viewModel,
            input: io.input,
            feeLoader: feeLoader,
            title: builder.summaryTitle(action: actionType)
        )

        return (step: step, interactor: interactor)
    }
}

// MARK: - Private

private extension SendNewSummaryStepBuilder {
    func makeSendSummaryViewModel(
        interactor: SendSummaryInteractor,
        actionType: SendFlowActionType,
        notificationManager: NotificationManager,
        destinationEditableType: SendSummaryViewModel.EditableType,
        amountEditableType: SendSummaryViewModel.EditableType,
        sendDestinationCompactViewModel: SendNewDestinationCompactViewModel?,
        sendAmountCompactViewModel: SendNewAmountCompactViewModel?,
        sendReceiveTokenCompactViewModel: SendNewAmountCompactViewModel?,
        stakingValidatorsCompactViewModel: StakingValidatorsCompactViewModel?,
        sendFeeCompactViewModel: SendNewFeeCompactViewModel?
    ) -> SendNewSummaryViewModel {
        let settings = SendNewSummaryViewModel.Settings(
            tokenItem: tokenItem,
            destinationEditableType: destinationEditableType,
            amountEditableType: amountEditableType,
            actionType: actionType
        )

        return SendNewSummaryViewModel(
            settings: settings,
            interactor: interactor,
            notificationManager: notificationManager,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            sendReceiveTokenCompactViewModel: sendReceiveTokenCompactViewModel,
            sendDestinationCompactViewModel: sendDestinationCompactViewModel,
            stakingValidatorsCompactViewModel: stakingValidatorsCompactViewModel,
            sendFeeCompactViewModel: sendFeeCompactViewModel
        )
    }

    func makeSendSummaryInteractor(
        io: IO,
        descriptionBuilder: any SendTransactionSummaryDescriptionBuilder
    ) -> SendSummaryInteractor {
        CommonSendSummaryInteractor(
            input: io.input,
            output: io.output,
            descriptionBuilder: descriptionBuilder
        )
    }
}
