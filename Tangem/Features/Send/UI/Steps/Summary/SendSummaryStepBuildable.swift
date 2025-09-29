//
//  SendSummaryStepBuildable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol SendSummaryStepBuildable {
    var summaryIO: SendSummaryStepBuilder.IO { get }
    var summaryTypes: SendSummaryStepBuilder.Types { get }
    var summaryDependencies: SendSummaryStepBuilder.Dependencies { get }
}

extension SendSummaryStepBuildable {
    func makeSendSummaryStep(
        stakingValidatorsCompactViewModel: StakingValidatorsCompactViewModel? = nil,
        sendAmountCompactViewModel: SendAmountCompactViewModel? = nil,
        sendFeeCompactViewModel: SendFeeCompactViewModel? = nil
    ) -> SendSummaryStepBuilder.ReturnValue {
        SendSummaryStepBuilder.make(
            io: summaryIO,
            types: summaryTypes,
            dependencies: summaryDependencies,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            stakingValidatorsCompactViewModel: stakingValidatorsCompactViewModel,
            sendFeeCompactViewModel: sendFeeCompactViewModel,
        )
    }
}

enum SendSummaryStepBuilder {
    struct IO {
        let input: SendSummaryInput
        let output: SendSummaryOutput
    }

    struct Types {
        let settings: SendSummaryViewModel.Settings
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
        sendAmountCompactViewModel: SendAmountCompactViewModel?,
        stakingValidatorsCompactViewModel: StakingValidatorsCompactViewModel?,
        sendFeeCompactViewModel: SendFeeCompactViewModel?,
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
