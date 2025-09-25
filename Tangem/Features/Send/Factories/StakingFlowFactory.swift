//
//  StakingFlowFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

class StakingFlowFactory {
    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem
    private let manager: any StakingManager

    private let builder: SendDependenciesBuilder

    // Sharing

    lazy var analyticsLogger = builder.makeStakingSendAnalyticsLogger(actionType: .stake)
    lazy var stakingModel = builder.makeStakingModel(stakingManager: manager, analyticsLogger: analyticsLogger)
    lazy var notificationManager = builder.makeStakingNotificationManager()

    init(walletModel: any WalletModel, manager: any StakingManager, input: SendDependenciesBuilder.Input) {
        self.tokenItem = walletModel.tokenItem
        self.feeTokenItem = walletModel.feeTokenItem
        self.manager = manager

        builder = .init(input: input)
    }

    func make(router: any SendRoutable) -> SendViewModel {
        let sendFeeCompactViewModel = SendFeeCompactViewModel(
            input: stakingModel,
            feeTokenItem: feeTokenItem,
            isFeeApproximate: builder.isFeeApproximate()
        )

        let amount = makeSendAmountStep()
        let validators = makeStakingValidatorsStep()

        let summary = makeSendSummaryStep(
            stakingValidatorsCompactViewModel: validators.compact,
            sendAmountCompactViewModel: amount.compact,
            sendFeeCompactViewModel: sendFeeCompactViewModel,
        )

        let finish = makeSendFinishStep(
            sendAmountCompactViewModel: amount.compact,
            stakingValidatorsCompactViewModel: validators.compact,
            sendFeeCompactViewModel: sendFeeCompactViewModel,
            router: router
        )

        // Steps
        sendFeeCompactViewModel.bind(input: stakingModel)

        // Notifications setup
        notificationManager.setup(provider: stakingModel, input: stakingModel)
        notificationManager.setupManager(with: stakingModel)

        let stepsManager = CommonStakingStepsManager(
            provider: stakingModel,
            amountStep: amount.step,
            validatorsStep: validators.step,
            summaryStep: summary.step,
            finishStep: finish,
            summaryTitleProvider: builder.makeStakingSummaryTitleProvider(actionType: .stake)
        )

        let viewModel = makeSendBase(stepsManager: stepsManager, router: router)

        summary.step.set(router: stepsManager)

        stakingModel.router = viewModel

        return viewModel
    }

    func makeStakingValidatorsStep() -> StakingValidatorsStepBuilder2.ReturnValue {
        let io = StakingValidatorsStepBuilder2.IO(input: stakingModel, output: stakingModel)

        let types = StakingValidatorsStepBuilder2.Types(actionType: .stake, currentValidator: .none)

        let dependencies = StakingValidatorsStepBuilder2.Dependencies(
            manager: manager,
            sendFeeProvider: stakingModel,
            analyticsLogger: analyticsLogger
        )

        return StakingValidatorsStepBuilder2.make(io: io, types: types, dependencies: dependencies)
    }
}

// MARK: - SendBaseBuildable

extension StakingFlowFactory: SendBaseBuildable {
    var baseIO: SendViewModelBuilder.IO {
        SendViewModelBuilder.IO(input: stakingModel, output: stakingModel)
    }
    
    var baseTypes: SendViewModelBuilder.Types {
        SendViewModelBuilder.Types(tokenItem: tokenItem)
    }
    
    var baseDependencies: SendViewModelBuilder.Dependencies {
        SendViewModelBuilder.Dependencies(
            alertBuilder: builder.makeStakingAlertBuilder(),
            dataBuilder: builder.makeStakingBaseDataBuilder(input: stakingModel),
            analyticsLogger: analyticsLogger,
            blockchainSDKNotificationMapper: builder.makeBlockchainSDKNotificationMapper()
        )
    }
}

// MARK: - SendAmountStepBuildable

extension StakingFlowFactory: SendAmountStepBuildable {
    var amountIO: SendAmountStepBuilder2.IO {
        SendAmountStepBuilder2.IO(input: stakingModel, output: stakingModel)
    }
    
    var amountTypes: SendAmountStepBuilder2.Types {
        SendAmountStepBuilder2.Types(
            tokenItem: tokenItem,
            feeTokenItem: feeTokenItem,
            maxAmount: builder.maxAmount(for: stakingModel.amount, actionType: .stake),
            settings: .init(
                walletHeaderText: builder.walletHeaderText(for: .stake),
                tokenItem: tokenItem,
                tokenIconInfo: builder.makeTokenIconInfo(),
                balanceFormatted: builder.formattedBalance(for: stakingModel.amount, actionType: .stake),
                currencyPickerData: builder.makeCurrencyPickerData()
            )
        )
    }
    
    var amountDependencies: SendAmountStepBuilder2.Dependencies {
        SendAmountStepBuilder2.Dependencies(
            sendFeeProvider: stakingModel,
            sendQRCodeService: .none,
            sendAmountValidator: builder.makeStakingSendAmountValidator(stakingManager: manager),
            amountModifier: builder.makeStakingAmountModifier(actionType: .stake),
            analyticsLogger: analyticsLogger
        )
    }
}

// MARK: - SendAmountStepBuildable

extension StakingFlowFactory: SendSummaryStepBuildable {
    var summaryIO: SendSummaryStepBuilder2.IO {
        SendSummaryStepBuilder2.IO(input: stakingModel, output: stakingModel)
    }
    
    var summaryTypes: SendSummaryStepBuilder2.Types {
        SendSummaryStepBuilder2.Types(
            settings: .init(
                tokenItem: tokenItem,
                destinationEditableType: .editable,
                amountEditableType: .editable,
                actionType: .stake
            )
        )
    }
    
    var summaryDependencies: SendSummaryStepBuilder2.Dependencies {
        SendSummaryStepBuilder2.Dependencies(
            sendFeeProvider: stakingModel,
            notificationManager: notificationManager,
            analyticsLogger: analyticsLogger,
            sendDescriptionBuilder: builder.makeSendTransactionSummaryDescriptionBuilder(),
            stakingDescriptionBuilder: builder.makeStakingTransactionSummaryDescriptionBuilder()
        )
    }
}

// MARK: - SendAmountStepBuildable

extension StakingFlowFactory: SendFinishStepBuildable {
    var finishIO: SendFinishStepBuilder2.IO {
        SendFinishStepBuilder2.IO(input: stakingModel)
    }
    
    var finishTypes: SendFinishStepBuilder2.Types {
        SendFinishStepBuilder2.Types(tokenItem: tokenItem)
    }
    
    var finishDependencies: SendFinishStepBuilder2.Dependencies {
        SendFinishStepBuilder2.Dependencies(
            analyticsLogger: analyticsLogger,
        )
    }
}
