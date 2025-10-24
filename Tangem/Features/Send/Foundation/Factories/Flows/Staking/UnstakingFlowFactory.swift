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
            sendSourceToken: makeSourceToken(),
            transactionDispatcher: makeStakingTransactionDispatcher(
                stakingManger: stakingManager,
                analyticsLogger: analyticsLogger
            ),
            analyticsLogger: analyticsLogger,
            action: action,
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
        amount.amountUpdater.externalUpdate(amount: action.amount)

        let sendFeeCompactViewModel = SendNewFeeCompactViewModel(
            feeTokenItem: feeTokenItem,
            isFeeApproximate: isFeeApproximate()
        )

        let sendFeeFinishViewModel = SendFeeFinishViewModel(
            feeTokenItem: feeTokenItem,
            isFeeApproximate: isFeeApproximate()
        )

        let summary = makeSendNewSummaryStep(
            sendAmountCompactViewModel: amount.compact,
            sendFeeCompactViewModel: sendFeeCompactViewModel,
        )

        let finish = makeSendFinishStep(
            sendAmountFinishViewModel: amount.finish,
            sendFeeFinishViewModel: sendFeeFinishViewModel,
            router: router
        )

        // Steps
        sendFeeCompactViewModel.bind(input: unstakingModel)
        sendFeeFinishViewModel.bind(input: unstakingModel)

        // Notifications setup
        notificationManager.setup(provider: unstakingModel, input: unstakingModel)
        notificationManager.setupManager(with: unstakingModel)

        // Analytics
        analyticsLogger.setup(stakingValidatorsInput: unstakingModel)

        let stepsManager = CommonUnstakingStepsManager(
            amountStep: amount.step,
            summaryStep: summary,
            finishStep: finish,
            summaryTitleProvider: makeStakingSummaryTitleProvider(),
            action: action,
            isPartialUnstakeAllowed: isPartialUnstakeAllowed
        )

        let viewModel = makeSendBase(stepsManager: stepsManager, router: router)

        summary.set(router: stepsManager)
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

// MARK: - SendNewAmountStepBuildable

extension UnstakingFlowFactory: SendNewAmountStepBuildable {
    var newAmountIO: SendNewAmountStepBuilder.IO {
        SendNewAmountStepBuilder.IO(
            sourceIO: (input: unstakingModel, output: unstakingModel),
            sourceAmountIO: (input: unstakingModel, output: unstakingModel)
        )
    }

    var newAmountDependencies: SendNewAmountStepBuilder.Dependencies {
        SendNewAmountStepBuilder.Dependencies(
            sendAmountValidator: UnstakingAmountValidator(
                tokenItem: tokenItem,
                stakedAmount: action.amount,
                stakingManagerStatePublisher: manager.statePublisher
            ),
            amountModifier: .none,
            notificationService: .none,
            analyticsLogger: analyticsLogger
        )
    }
}

// MARK: - SendNewSummaryStepBuildable

extension UnstakingFlowFactory: SendNewSummaryStepBuildable {
    var newSummaryIO: SendNewSummaryStepBuilder.IO {
        SendNewSummaryStepBuilder.IO(input: unstakingModel, output: unstakingModel)
    }

    var newSummaryTypes: SendNewSummaryStepBuilder.Types {
        SendNewSummaryStepBuilder.Types(
            settings: .init(
                destinationEditableType: unstakingModel.isPartialUnstakeAllowed ? .editable : .noEditable,
                amountEditableType: unstakingModel.isPartialUnstakeAllowed ? .editable : .noEditable,
            )
        )
    }

    var newSummaryDependencies: SendNewSummaryStepBuilder.Dependencies {
        SendNewSummaryStepBuilder.Dependencies(
            sendFeeProvider: unstakingModel,
            notificationManager: notificationManager,
            analyticsLogger: analyticsLogger,
            sendDescriptionBuilder: makeSendTransactionSummaryDescriptionBuilder(),
            swapDescriptionBuilder: makeSwapTransactionSummaryDescriptionBuilder(),
            stakingDescriptionBuilder: makeStakingTransactionSummaryDescriptionBuilder()
        )
    }
}

// MARK: - SendNewFinishStepBuildable

extension UnstakingFlowFactory: SendNewFinishStepBuildable {
    var newFinishIO: SendNewFinishStepBuilder.IO {
        SendNewFinishStepBuilder.IO(input: unstakingModel)
    }

    var newFinishTypes: SendNewFinishStepBuilder.Types {
        SendNewFinishStepBuilder.Types(tokenItem: tokenItem)
    }

    var newFinishDependencies: SendNewFinishStepBuilder.Dependencies {
        SendNewFinishStepBuilder.Dependencies(analyticsLogger: analyticsLogger)
    }
}
