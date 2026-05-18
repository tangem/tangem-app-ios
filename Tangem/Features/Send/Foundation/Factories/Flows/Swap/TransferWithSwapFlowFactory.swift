//
//  TransferWithSwapFlowFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import struct TangemUI.TokenIconInfo

/// Swap-screen flow with an embedded Transfer mode (same-token send between accounts).
/// Mirror of `SendWithSwapFlowFactory`, but oriented around the Swap screen as the primary surface.
class TransferWithSwapFlowFactory: SendWithSwapFlowBaseDependenciesFactory {
    var transferableToken: SendTransferableToken { sourceToken }
    var tokenItem: TokenItem { transferableToken.tokenItem }

    let sourceToken: SendWithSwapToken
    let initialReceiveToken: SendReceiveToken?
    let expressDependenciesFactory: ExpressDependenciesFactory

    lazy var autoupdatingTimer = AutoupdatingTimer()
    lazy var analyticsLogger: SendAnalyticsLogger = makeSendAnalyticsLogger(sendType: .transferAndSwap)

    lazy var sendNotificationManager = makeSendNotificationManager()
    lazy var swapNotificationManager = makeSwapNotificationManager()
    lazy var notificationManager: NotificationManager = TransferWithSwapNotificationManager(
        transferWithSwapModelInput: transferWithSwapModel,
        sendNotificationManager: sendNotificationManager,
        swapNotificationManager: swapNotificationManager
    )

    lazy var transferModel = makeTransferModel(
        analyticsLogger: analyticsLogger,
        predefinedValues: .init()
    )
    lazy var swapModel = makeSwapModel(
        sourceToken: sourceToken,
        receiveToken: initialReceiveToken,
        analyticsLogger: analyticsLogger,
        autoupdatingTimer: autoupdatingTimer,
        pairUpdateHandler: RegularSwapPairUpdateHandler(
            expressManager: expressDependenciesFactory.expressManager,
            expressPairsRepository: expressDependenciesFactory.expressPairsRepository
        ),
        shouldStartInitialLoading: true
    )
    lazy var transferWithSwapModel = TransferWithSwapModel(
        swapModel: swapModel,
        transferModel: transferModel,
        analyticsLogger: analyticsLogger
    )

    init(sourceToken: SendWithSwapToken, receiveToken: SendReceiveToken?) {
        self.sourceToken = sourceToken
        initialReceiveToken = receiveToken
        expressDependenciesFactory = CommonExpressDependenciesFactory(
            userWalletInfo: sourceToken.userWalletInfo
        )
    }
}

// MARK: - SendGenericFlowFactory

extension TransferWithSwapFlowFactory: SendGenericFlowFactory {
    func make(router: any SendRoutable, coordinatorStateProvider: SendCoordinatorStateProvider) -> SendViewModel {
        let amount = makeSwapAmountStep()
        let fee = makeSendFeeStep(router: router)
        let providers = makeSwapProviders()

        let summary = makeSwapSummaryStep(
            swapAmountViewModel: amount.viewModel,
            swapSummaryProviderViewModel: providers.compact,
            feeCompactViewModel: fee.compact,
        )

        let finish = makeSendFinishStep(
            sendAmountFinishViewModel: amount.finish,
            sendFeeFinishViewModel: fee.finish,
            router: router
        )

        // Forward updaters to internal models
        transferModel.externalAmountUpdater = amount.amountUpdater
        swapModel.externalAmountUpdater = amount.amountUpdater

        // Steps setup
        fee.compact.bind(input: transferWithSwapModel)
        fee.finish.bind(input: transferWithSwapModel)

        // Notifications setup
        sendNotificationManager.setup(input: transferModel)
        sendNotificationManager.setupManager(with: transferModel)

        swapNotificationManager.setupManager(with: transferWithSwapModel)
        swapNotificationManager.setup(
            sourceTokenInput: swapModel,
            receiveTokenInput: swapModel,
            swapModelStateProvider: swapModel
        )

        // Logger setup
        analyticsLogger.setup(sendFeeInput: transferWithSwapModel)
        analyticsLogger.setup(sendSourceTokenInput: transferWithSwapModel)
        analyticsLogger.setup(sendReceiveTokenInput: transferWithSwapModel)
        analyticsLogger.setup(sendSwapProvidersInput: transferWithSwapModel)

        let tokenSelectorBuilder = SwapTokenSelectorViewModelBuilder(output: transferWithSwapModel)

        let stepsManager = CommonSwapStepsManager(
            summaryStep: summary,
            finishStep: finish,
            feeSelectorBuilder: fee.feeSelectorBuilder,
            providersSelector: providers.selector,
            tokenSelectorBuilder: tokenSelectorBuilder,
            router: router
        )

        let viewModel = makeSendBase(stepsManager: stepsManager, router: router)
        summary.set(router: stepsManager)

        swapModel.router = viewModel
        swapModel.alertPresenter = viewModel
        transferWithSwapModel.router = viewModel
        transferWithSwapModel.alertPresenter = viewModel

        // TransferModel needs an alert presenter and router too; it shares the same SendViewModel.
        transferModel.router = viewModel

        coordinatorStateProvider.setup(autoupdatingTimer: autoupdatingTimer)

        return viewModel
    }
}

// MARK: - SendBaseBuildable

extension TransferWithSwapFlowFactory: SendBaseBuildable {
    var baseIO: SendViewModelBuilder.IO {
        SendViewModelBuilder.IO(input: transferWithSwapModel, output: transferWithSwapModel)
    }

    var baseDependencies: SendViewModelBuilder.Dependencies {
        SendViewModelBuilder.Dependencies(
            alertBuilder: makeSwapAlertBuilder(),
            mailDataBuilder: CommonSendMailDataBuilder(
                baseDataInput: transferWithSwapModel,
                sourceTokenInput: transferWithSwapModel
            ),
            approveViewModelInputDataBuilder: CommonApproveViewModelInputDataBuilder(
                dataProvider: transferWithSwapModel,
                analyticsLogger: analyticsLogger,
                output: transferWithSwapModel,
                confirmTransactionPolicy: CommonConfirmTransactionPolicy(userWalletInfo: sourceToken.userWalletInfo)
            ),
            feeCurrencyProviderDataBuilder: CommonSendFeeCurrencyProviderDataBuilder(
                sourceTokenInput: transferWithSwapModel
            ),
            analyticsLogger: analyticsLogger,
            blockchainSDKNotificationMapper: BlockchainSDKNotificationMapper(tokenItem: tokenItem),
            tangemIconProvider: sourceToken.tangemIconProvider
        )
    }
}

// MARK: - SwapAmountStepBuildable

extension TransferWithSwapFlowFactory: SwapAmountStepBuildable {
    var amountIO: SwapAmountStepBuilder.IO {
        SwapAmountStepBuilder.IO(
            sourceIO: (input: transferWithSwapModel, output: transferWithSwapModel),
            sourceAmountIO: (input: transferWithSwapModel, output: transferWithSwapModel),
            receiveIO: (input: transferWithSwapModel, output: transferWithSwapModel),
            receiveAmountIO: (input: transferWithSwapModel, output: transferWithSwapModel),
            swapProvidersInput: transferWithSwapModel,
            stateProvider: swapModel
        )
    }

    var amountTypes: SwapAmountStepBuilder.Types {
        .init(initialTokenItem: tokenItem)
    }

    var amountDependencies: SwapAmountStepBuilder.Dependencies {
        SwapAmountStepBuilder.Dependencies(
            sendAmountValidator: CommonSwapAmountValidator(),
            analyticsLogger: analyticsLogger,
            isFixedRateMode: false
        )
    }
}

// MARK: - SwapSummaryStepBuildable

extension TransferWithSwapFlowFactory: SwapSummaryStepBuildable {
    var summaryIO: SwapSummaryStepBuilder.IO {
        SwapSummaryStepBuilder.IO(
            input: transferWithSwapModel,
            output: transferWithSwapModel,
            sourceTokenInput: transferWithSwapModel,
            sourceTokenAmountInput: transferWithSwapModel,
            receiveTokenInput: transferWithSwapModel,
            receiveTokenAmountInput: transferWithSwapModel,
            transferWithSwapModelInput: transferWithSwapModel
        )
    }

    var summaryDependencies: SwapSummaryStepBuilder.Dependencies {
        SwapSummaryStepBuilder.Dependencies(
            notificationManager: notificationManager,
            autoupdatingTimer: autoupdatingTimer,
            analyticsLogger: analyticsLogger,
            swapDescriptionBuilder: makeSwapTransactionSummaryDescriptionBuilder(),
        )
    }
}

// MARK: - SendFeeStepBuildable

extension TransferWithSwapFlowFactory: SendFeeStepBuildable {
    var feeDependencies: SendFeeStepBuilder.Dependencies {
        SendFeeStepBuilder.Dependencies(
            tokenFeeManagerProviding: transferWithSwapModel,
            feeSelectorOutput: transferWithSwapModel,
            analyticsLogger: analyticsLogger
        )
    }
}

// MARK: - SendSwapProvidersBuildable

extension TransferWithSwapFlowFactory: SendSwapProvidersBuildable {
    var swapProvidersIO: SendSwapProvidersBuilder.IO {
        SendSwapProvidersBuilder.IO(
            input: transferWithSwapModel,
            output: transferWithSwapModel,
            sourceTokenInput: transferWithSwapModel,
            receiveTokenInput: transferWithSwapModel,
            receiveTokenAmountInput: transferWithSwapModel
        )
    }

    var swapProvidersTypes: SendSwapProvidersBuilder.Types {
        SendSwapProvidersBuilder.Types(tokenItem: tokenItem)
    }

    var swapProvidersDependencies: SendSwapProvidersBuilder.Dependencies {
        SendSwapProvidersBuilder.Dependencies(
            analyticsLogger: analyticsLogger,
            expressProviderFormatter: .init(balanceFormatter: .init()),
            priceChangeFormatter: .init(percentFormatter: .init())
        )
    }
}

// MARK: - SendFinishStepBuildable

extension TransferWithSwapFlowFactory: SendFinishStepBuildable {
    var finishIO: SendFinishStepBuilder.IO {
        SendFinishStepBuilder.IO(input: transferWithSwapModel)
    }

    var finishTypes: SendFinishStepBuilder.Types {
        SendFinishStepBuilder.Types(tokenItem: tokenItem, isSwapFlow: true)
    }

    var finishDependencies: SendFinishStepBuilder.Dependencies {
        SendFinishStepBuilder.Dependencies(
            analyticsLogger: analyticsLogger,
        )
    }
}
