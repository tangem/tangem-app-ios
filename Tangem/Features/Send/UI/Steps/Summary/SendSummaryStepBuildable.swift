//
//  SendSummaryStepBuildable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol SendSummaryStepBuildable {
    var summaryIO: SendSummaryStepBuilder2.IO { get }
    var summaryTypes: SendSummaryStepBuilder2.Types { get }
    var summaryDependencies: SendSummaryStepBuilder2.Dependencies { get }
}

extension SendSummaryStepBuildable {
    func makeSendSummaryStep(
        stakingValidatorsCompactViewModel: StakingValidatorsCompactViewModel,
        sendAmountCompactViewModel: SendAmountCompactViewModel,
        sendFeeCompactViewModel: SendFeeCompactViewModel
    ) -> SendSummaryStepBuilder2.ReturnValue {
        SendSummaryStepBuilder2.make(
            io: summaryIO,
            types: summaryTypes,
            dependencies: summaryDependencies,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            stakingValidatorsCompactViewModel: stakingValidatorsCompactViewModel,
            sendFeeCompactViewModel: sendFeeCompactViewModel,
        )
    }
}

enum SendSummaryStepBuilder2 {
    struct IO {
        let input: SendSummaryInput
        let output: SendSummaryOutput
    }

    struct Types {
        let settings: SendSummaryViewModel.Settings

        /*
         SendSummaryViewModel.Settings(
             tokenItem: walletModel.tokenItem,
             destinationEditableType: destinationEditableType,
             amountEditableType: amountEditableType,
             actionType: actionType
         )
          */
    }

    struct Dependencies {
        let sendFeeProvider: any SendFeeProvider
        let notificationManager: any NotificationManager
        let analyticsLogger: any SendSummaryAnalyticsLogger
        let sendDescriptionBuilder: any SendTransactionSummaryDescriptionBuilder
        let stakingDescriptionBuilder: any StakingTransactionSummaryDescriptionBuilder
    }

    typealias ReturnValue = (step: SendSummaryStep, interactor: SendSummaryInteractor)

    static func make(
        io: IO,
        types: Types,
        dependencies: Dependencies,
//        actionType: SendFlowActionType,
//        notificationManager: NotificationManager,
//        destinationEditableType: SendSummaryViewModel.EditableType,
//        amountEditableType: SendSummaryViewModel.EditableType,
        sendAmountCompactViewModel: SendAmountCompactViewModel?,
        stakingValidatorsCompactViewModel: StakingValidatorsCompactViewModel?,
        sendFeeCompactViewModel: SendFeeCompactViewModel?,
//        analyticsLogger: any SendSummaryAnalyticsLogger
    ) -> ReturnValue {
        let interactor = CommonSendSummaryInteractor(
            input: io.input,
            output: io.output,
            sendDescriptionBuilder: dependencies.sendDescriptionBuilder,
            stakingDescriptionBuilder: dependencies.stakingDescriptionBuilder
        )

        let viewModel = SendSummaryViewModel(
            settings: types.settings,
            interactor: interactor,
            notificationManager: dependencies.notificationManager,
            analyticsLogger: dependencies.analyticsLogger,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            stakingValidatorsCompactViewModel: stakingValidatorsCompactViewModel,
            sendFeeCompactViewModel: sendFeeCompactViewModel,
        )

        let step = SendSummaryStep(
            viewModel: viewModel,
            input: io.input,
            analyticsLogger: dependencies.analyticsLogger
        )

        return (step: step, interactor: interactor)
    }
}
