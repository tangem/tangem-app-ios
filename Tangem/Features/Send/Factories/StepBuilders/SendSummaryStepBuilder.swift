//
//  SendSummaryStepBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SendSummaryStepBuilder {
    typealias IO = (input: SendSummaryInput, output: SendSummaryOutput)
    typealias ReturnValue = (step: SendSummaryStep, interactor: SendSummaryInteractor)

    let walletModel: any WalletModel
    let builder: SendDependenciesBuilder

    func makeSendSummaryStep(
        io: IO,
        actionType: SendFlowActionType,
        descriptionBuilder: any SendTransactionSummaryDescriptionBuilder,
        notificationManager: NotificationManager,
        destinationEditableType: SendSummaryViewModel.EditableType,
        amountEditableType: SendSummaryViewModel.EditableType,
        sendDestinationCompactViewModel: SendDestinationCompactViewModel?,
        sendAmountCompactViewModel: SendAmountCompactViewModel?,
        stakingValidatorsCompactViewModel: StakingValidatorsCompactViewModel?,
        sendFeeCompactViewModel: SendFeeCompactViewModel?,
        analyticsLogger: any SendSummaryAnalyticsLogger
    ) -> ReturnValue {
        let interactor = makeSendSummaryInteractor(
            io: io,
            descriptionBuilder: descriptionBuilder
        )

        let viewModel = makeSendSummaryViewModel(
            interactor: interactor,
            actionType: actionType,
            notificationManager: notificationManager,
            analyticsLogger: analyticsLogger,
            destinationEditableType: destinationEditableType,
            amountEditableType: amountEditableType,
            sendDestinationCompactViewModel: sendDestinationCompactViewModel,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            stakingValidatorsCompactViewModel: stakingValidatorsCompactViewModel,
            sendFeeCompactViewModel: sendFeeCompactViewModel
        )

        let step = SendSummaryStep(
            viewModel: viewModel,
            input: io.input,
            analyticsLogger: analyticsLogger,
            title: builder.summaryTitle(action: actionType),
            subtitle: builder.summarySubtitle(action: actionType)
        )

        return (step: step, interactor: interactor)
    }
}

// MARK: - Private

private extension SendSummaryStepBuilder {
    func makeSendSummaryViewModel(
        interactor: SendSummaryInteractor,
        actionType: SendFlowActionType,
        notificationManager: NotificationManager,
        analyticsLogger: any SendSummaryAnalyticsLogger,
        destinationEditableType: SendSummaryViewModel.EditableType,
        amountEditableType: SendSummaryViewModel.EditableType,
        sendDestinationCompactViewModel: SendDestinationCompactViewModel?,
        sendAmountCompactViewModel: SendAmountCompactViewModel?,
        stakingValidatorsCompactViewModel: StakingValidatorsCompactViewModel?,
        sendFeeCompactViewModel: SendFeeCompactViewModel?
    ) -> SendSummaryViewModel {
        let settings = SendSummaryViewModel.Settings(
            tokenItem: walletModel.tokenItem,
            destinationEditableType: destinationEditableType,
            amountEditableType: amountEditableType,
            actionType: actionType
        )

        return SendSummaryViewModel(
            settings: settings,
            interactor: interactor,
            notificationManager: notificationManager,
            analyticsLogger: analyticsLogger,
            sendDestinationCompactViewModel: sendDestinationCompactViewModel,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            stakingValidatorsCompactViewModel: stakingValidatorsCompactViewModel,
            sendFeeCompactViewModel: sendFeeCompactViewModel,
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
