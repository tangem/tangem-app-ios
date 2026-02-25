//
//  SwapFlowFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct TangemUI.TokenIconInfo

class SwapFlowFactory: SwapFlowBaseDependenciesFactory {
    let sourceToken: SendSourceToken
    let initialTokenItem: TokenItem
    let expressDependenciesFactory: ExpressDependenciesFactory

    lazy var analyticsLogger: SendAnalyticsLogger = makeSendAnalyticsLogger(sendType: .swap)
    lazy var swapModel = makeSwapModel(
        sourceToken: sourceToken,
        analyticsLogger: analyticsLogger,
        autoupdatingTimer: autoupdatingTimer,
        shouldStartInitialLoading: true
    )
    lazy var notificationManager = makeSwapNotificationManager()
    lazy var autoupdatingTimer = AutoupdatingTimer()

    init(sourceToken: SendSourceToken) {
        self.sourceToken = sourceToken
        self.initialTokenItem = sourceToken.tokenItem

        expressDependenciesFactory = CommonExpressDependenciesFactory(userWalletInfo: sourceToken.userWalletInfo)
    }
}

// MARK: - SendGenericFlowFactory

extension SwapFlowFactory: SendGenericFlowFactory {
    func make(router: any SendRoutable) -> SendViewModel {
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

        // Steps setup
        fee.compact.bind(input: swapModel)
        fee.finish.bind(input: swapModel)

        // Notifications setup
        notificationManager.setupManager(with: swapModel)
        notificationManager.setup(
            sourceTokenInput: swapModel,
            receiveTokenInput: swapModel,
            swapModelStateProvider: swapModel
        )

        // Logger setup
        analyticsLogger.setup(sendFeeInput: swapModel)
        analyticsLogger.setup(sendSourceTokenInput: swapModel)
        analyticsLogger.setup(sendReceiveTokenInput: swapModel)
        analyticsLogger.setup(sendSwapProvidersInput: swapModel)

        let tokenSelectorBuilder = SwapTokenSelectorViewModelBuilder(output: swapModel)

        let stepsManager = CommonSwapStepsManager(
            summaryStep: summary,
            finishStep: finish,
            feeSelectorBuilder: fee.feeSelectorBuilder,
            providersSelector: providers.selector,
            tokenSelectorBuilder: tokenSelectorBuilder,
            autoupdatingTimer: autoupdatingTimer,
            router: router
        )

        let viewModel = makeSendBase(stepsManager: stepsManager, router: router)
        summary.set(router: stepsManager)

        swapModel.router = viewModel
        swapModel.alertPresenter = viewModel
        swapModel.externalAmountUpdater = amount.amountUpdater

        return viewModel
    }
}

// MARK: - SendBaseBuildable

extension SwapFlowFactory: SendBaseBuildable {
    var baseIO: SendViewModelBuilder.IO {
        SendViewModelBuilder.IO(input: swapModel, output: swapModel)
    }

    var baseDependencies: SendViewModelBuilder.Dependencies {
        SendViewModelBuilder.Dependencies(
            alertBuilder: makeSwapAlertBuilder(),
            mailDataBuilder: CommonSendMailDataBuilder(
                baseDataInput: swapModel,
                emailDataCollectorBuilder: sourceToken.emailDataCollectorBuilder,
                emailDataProvider: sourceToken.userWalletInfo.emailDataProvider,
            ),
            approveViewModelInputDataBuilder: CommonSendApproveViewModelInputDataBuilder(
                sourceToken: sourceToken,
                approveDataInput: swapModel
            ),
            feeCurrencyProviderDataBuilder: CommonSendFeeCurrencyProviderDataBuilder(
                sourceToken: sourceToken
            ),
            analyticsLogger: analyticsLogger,
            blockchainSDKNotificationMapper: BlockchainSDKNotificationMapper(tokenItem: sourceToken.tokenItem),
            tangemIconProvider: CommonTangemIconProvider(config: sourceToken.userWalletInfo.config)
        )
    }
}

// MARK: - SendAmountStepBuildable

extension SwapFlowFactory: SwapAmountStepBuildable {
    var amountIO: SwapAmountStepBuilder.IO {
        SwapAmountStepBuilder.IO(
            sourceIO: (input: swapModel, output: swapModel),
            sourceAmountIO: (input: swapModel, output: swapModel),
            receiveIO: (input: swapModel, output: swapModel),
            receiveAmountIO: (input: swapModel, output: swapModel),
            swapProvidersInput: swapModel,
            stateProvider: swapModel
        )
    }

    var amountTypes: SwapAmountStepBuilder.Types {
        .init(initialSourceToken: sourceToken)
    }

    var amountDependencies: SwapAmountStepBuilder.Dependencies {
        SwapAmountStepBuilder.Dependencies(
            sendAmountValidator: CommonSwapAmountValidator(),
            analyticsLogger: analyticsLogger
        )
    }
}

// MARK: - SendSummaryStepBuildable

extension SwapFlowFactory: SwapSummaryStepBuildable {
    var summaryIO: SwapSummaryStepBuilder.IO {
        SwapSummaryStepBuilder.IO(
            input: swapModel,
            output: swapModel,
            sourceTokenInput: swapModel,
            sourceTokenAmountInput: swapModel,
            receiveTokenInput: swapModel,
            receiveTokenAmountInput: swapModel
        )
    }

    var summaryDependencies: SwapSummaryStepBuilder.Dependencies {
        SwapSummaryStepBuilder.Dependencies(
            notificationManager: notificationManager,
            analyticsLogger: analyticsLogger,
            swapDescriptionBuilder: makeSwapTransactionSummaryDescriptionBuilder(),
        )
    }
}

// MARK: - SendFeeStepBuildable

extension SwapFlowFactory: SendFeeStepBuildable {
    var feeDependencies: SendFeeStepBuilder.Dependencies {
        SendFeeStepBuilder.Dependencies(
            tokenFeeManagerProviding: swapModel,
            feeSelectorOutput: swapModel,
            analyticsLogger: analyticsLogger
        )
    }
}

// MARK: - SendSwapProvidersBuildable

extension SwapFlowFactory: SendSwapProvidersBuildable {
    var swapProvidersIO: SendSwapProvidersBuilder.IO {
        SendSwapProvidersBuilder.IO(
            input: swapModel,
            output: swapModel,
            sourceTokenInput: swapModel,
            receiveTokenInput: swapModel
        )
    }

    var swapProvidersTypes: SendSwapProvidersBuilder.Types {
        SendSwapProvidersBuilder.Types(tokenItem: initialTokenItem)
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

extension SwapFlowFactory: SendFinishStepBuildable {
    var finishIO: SendFinishStepBuilder.IO {
        SendFinishStepBuilder.IO(input: swapModel)
    }

    var finishTypes: SendFinishStepBuilder.Types {
        SendFinishStepBuilder.Types(tokenItem: initialTokenItem)
    }

    var finishDependencies: SendFinishStepBuilder.Dependencies {
        SendFinishStepBuilder.Dependencies(
            analyticsLogger: analyticsLogger,
        )
    }
}
