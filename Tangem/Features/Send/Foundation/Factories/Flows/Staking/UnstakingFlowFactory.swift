//
//  UnstakingFlowFactory 2.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking
import TangemLocalization
import struct TangemUI.TokenIconInfo

class UnstakingFlowFactory: StakingFlowDependenciesFactory {
    let tokenItem: TokenItem
    let feeTokenItem: TokenItem
    let tokenIconInfo: TokenIconInfo
    let userWalletInfo: UserWalletInfo
    let manager: any StakingManager
    let action: RestakingModel.Action
    var actionType: StakingAction.ActionType { action.displayType }

    let baseDataBuilderFactory: SendBaseDataBuilderFactory
    let walletModelDependenciesProvider: WalletModelDependenciesProvider
    let walletModelBalancesProvider: WalletModelBalancesProvider
    let transactionDispatcherFactory: TransactionDispatcherFactory

    lazy var analyticsLogger = makeStakingSendAnalyticsLogger()
    lazy var unstakingModel = makeUnstakingModel(stakingManager: manager, analyticsLogger: analyticsLogger)
    lazy var notificationManager = makeStakingNotificationManager()

    init(
        walletModel: any WalletModel,
        userWalletInfo: UserWalletInfo,
        manager: any StakingManager,
        action: UnstakingModel.Action,
    ) {
        self.userWalletInfo = userWalletInfo
        self.manager = manager
        self.action = action

        tokenItem = walletModel.tokenItem
        feeTokenItem = walletModel.feeTokenItem
        tokenIconInfo = TokenIconInfoBuilder().build(
            from: walletModel.tokenItem,
            isCustom: walletModel.isCustom
        )
        walletModelDependenciesProvider = walletModel
        walletModelBalancesProvider = walletModel
        transactionDispatcherFactory = TransactionDispatcherFactory(
            walletModel: walletModel,
            signer: userWalletInfo.signer
        )
        baseDataBuilderFactory = SendBaseDataBuilderFactory(
            walletModel: walletModel,
            userWalletInfo: userWalletInfo
        )
    }
}

// MARK: - Model

extension UnstakingFlowFactory {
    func makeUnstakingModel(
        stakingManager: some StakingManager,
        analyticsLogger: any StakingSendAnalyticsLogger
    ) -> UnstakingModel {
        UnstakingModel(
            stakingManager: stakingManager,
            transactionDispatcher: makeStakingTransactionDispatcher(
                stakingManger: stakingManager,
                analyticsLogger: analyticsLogger
            ),
            transactionValidator: walletModelDependenciesProvider.transactionValidator,
            analyticsLogger: analyticsLogger,
            action: action,
            tokenItem: tokenItem,
            feeTokenItem: feeTokenItem
        )
    }
}

// MARK: - Unstaking related

extension UnstakingFlowFactory {
    private var amount: SendAmount {
        let fiat = tokenItem.currencyId.flatMap {
            BalanceConverter().convertToFiat(action.amount, currencyId: $0)
        }
        return .init(type: .typical(crypto: action.amount, fiat: fiat))
    }

    func maxAmount() -> Decimal {
        amount.crypto ?? 0
    }

    func walletHeaderText() -> String {
        Localization.stakingStakedAmount
    }

    func formattedBalance() -> String {
        let formatter = BalanceFormatter()
        let cryptoFormatted = formatter.formatCryptoBalance(
            amount.crypto,
            currencyCode: tokenItem.currencySymbol
        )

        let fiatFormatted = formatter.formatFiatBalance(amount.fiat)
        return Localization.commonCryptoFiatFormat(cryptoFormatted, fiatFormatted)
    }
}

// MARK: - SendGenericFlowFactory

extension UnstakingFlowFactory: SendGenericFlowFactory {
    func make(router: any SendRoutable) -> SendViewModel {
        let isPartialUnstakeAllowed = unstakingModel.isPartialUnstakeAllowed

        let amount = makeSendAmountStep()
        amount.interactor.externalUpdate(amount: action.amount)

        let sendFeeCompactViewModel = SendFeeCompactViewModel(
            input: unstakingModel,
            feeTokenItem: feeTokenItem,
            isFeeApproximate: isFeeApproximate()
        )

        let summary = makeSendSummaryStep(
            sendAmountCompactViewModel: amount.compact,
            sendFeeCompactViewModel: sendFeeCompactViewModel,
        )

        let finish = makeSendFinishStep(
            sendAmountCompactViewModel: amount.compact,
            sendFeeCompactViewModel: sendFeeCompactViewModel,
            router: router
        )

        // Steps
        sendFeeCompactViewModel.bind(input: unstakingModel)

        // Notifications setup
        notificationManager.setup(provider: unstakingModel, input: unstakingModel)
        notificationManager.setupManager(with: unstakingModel)

        // Analytics
        analyticsLogger.setup(stakingValidatorsInput: unstakingModel)

        let stepsManager = CommonUnstakingStepsManager(
            amountStep: amount.step,
            summaryStep: summary.step,
            finishStep: finish,
            summaryTitleProvider: makeStakingSummaryTitleProvider(),
            action: action,
            isPartialUnstakeAllowed: isPartialUnstakeAllowed
        )

        let viewModel = makeSendBase(stepsManager: stepsManager, router: router)

        summary.step.set(router: stepsManager)
        unstakingModel.router = viewModel

        if !isPartialUnstakeAllowed {
            unstakingModel.updateFees()
        }

        return viewModel
    }
}

// MARK: - SendBaseBuildable

extension UnstakingFlowFactory: SendBaseBuildable {
    var baseIO: SendViewModelBuilder.IO {
        SendViewModelBuilder.IO(input: unstakingModel, output: unstakingModel)
    }

    var baseDependencies: SendViewModelBuilder.Dependencies {
        SendViewModelBuilder.Dependencies(
            alertBuilder: makeStakingAlertBuilder(),
            dataBuilder: makeStakingBaseDataBuilder(input: unstakingModel),
            analyticsLogger: analyticsLogger,
            blockchainSDKNotificationMapper: makeBlockchainSDKNotificationMapper()
        )
    }
}

// MARK: - SendAmountStepBuildable

extension UnstakingFlowFactory: SendAmountStepBuildable {
    var amountIO: SendAmountStepBuilder.IO {
        SendAmountStepBuilder.IO(input: unstakingModel, output: unstakingModel)
    }

    var amountTypes: SendAmountStepBuilder.Types {
        SendAmountStepBuilder.Types(
            tokenItem: tokenItem,
            feeTokenItem: feeTokenItem,
            maxAmount: maxAmount(),
            settings: makeSendAmountViewModelSettings()
        )
    }

    var amountDependencies: SendAmountStepBuilder.Dependencies {
        SendAmountStepBuilder.Dependencies(
            sendFeeProvider: unstakingModel,
            sendQRCodeService: .none,
            sendAmountValidator: UnstakingAmountValidator(
                tokenItem: tokenItem,
                stakedAmount: action.amount,
                stakingManagerStatePublisher: manager.statePublisher
            ),
            amountModifier: .none,
            analyticsLogger: analyticsLogger
        )
    }
}

// MARK: - SendSummaryStepBuildable

extension UnstakingFlowFactory: SendSummaryStepBuildable {
    var summaryIO: SendSummaryStepBuilder.IO {
        SendSummaryStepBuilder.IO(input: unstakingModel, output: unstakingModel)
    }

    var summaryTypes: SendSummaryStepBuilder.Types {
        SendSummaryStepBuilder.Types(
            settings: .init(
                tokenItem: tokenItem,
                destinationEditableType: unstakingModel.isPartialUnstakeAllowed ? .editable : .noEditable,
                amountEditableType: unstakingModel.isPartialUnstakeAllowed ? .editable : .noEditable,
                actionType: sendFlowActionType()
            )
        )
    }

    var summaryDependencies: SendSummaryStepBuilder.Dependencies {
        SendSummaryStepBuilder.Dependencies(
            sendFeeProvider: unstakingModel,
            notificationManager: notificationManager,
            analyticsLogger: analyticsLogger,
            sendDescriptionBuilder: makeSendTransactionSummaryDescriptionBuilder(),
            stakingDescriptionBuilder: makeStakingTransactionSummaryDescriptionBuilder()
        )
    }
}

// MARK: - SendFinishStepBuildable

extension UnstakingFlowFactory: SendFinishStepBuildable {
    var finishIO: SendFinishStepBuilder.IO {
        SendFinishStepBuilder.IO(input: unstakingModel)
    }

    var finishTypes: SendFinishStepBuilder.Types {
        SendFinishStepBuilder.Types(tokenItem: tokenItem)
    }

    var finishDependencies: SendFinishStepBuilder.Dependencies {
        SendFinishStepBuilder.Dependencies(
            analyticsLogger: analyticsLogger,
        )
    }
}
