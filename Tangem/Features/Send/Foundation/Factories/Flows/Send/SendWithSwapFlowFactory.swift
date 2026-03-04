//
//  SendWithSwapFlowFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct TangemUI.TokenIconInfo

class SendWithSwapFlowFactory: SendWithSwapFlowBaseDependenciesFactory {
    var transferableToken: SendTransferableToken { sourceToken }
    var tokenItem: TokenItem { transferableToken.tokenItem }

    let sourceToken: SendWithSwapToken
    let expressDependenciesFactory: ExpressDependenciesFactory

    lazy var autoupdatingTimer = AutoupdatingTimer()
    lazy var analyticsLogger: SendAnalyticsLogger = makeSendAnalyticsLogger(sendType: .send)

    lazy var sendNotificationManager = makeSendNotificationManager()
    lazy var swapNotificationManager = makeSwapNotificationManager()
    lazy var notificationManager = makeSendWithSwapNotificationManager(
        receiveTokenInput: swapModel,
        sendNotificationManager: sendNotificationManager,
        swapNotificationManager: swapNotificationManager
    )

    lazy var transferModel = makeTransferModel(analyticsLogger: analyticsLogger, predefinedValues: .init())
    private let isFixedRateMode = FeatureProvider.isAvailable(.expressFixedRates)

    lazy var swapModel = makeSwapModel(
        sourceToken: sourceToken,
        receiveToken: .none,
        analyticsLogger: analyticsLogger,
        autoupdatingTimer: autoupdatingTimer,
        shouldStartInitialLoading: false,
        isFixedRatesEnabled: isFixedRateMode
    )
    lazy var sendWithSwapModel = makeSendWithSwapModel(
        transferModel: transferModel,
        swapModel: swapModel,
        analyticsLogger: analyticsLogger,
        predefinedValues: .init(),
        autoupdatingTimer: autoupdatingTimer
    )

    init(sourceToken: SendWithSwapToken) {
        self.sourceToken = sourceToken
        expressDependenciesFactory = CommonExpressDependenciesFactory(userWalletInfo: sourceToken.userWalletInfo)
    }
}

// MARK: - SendGenericFlowFactory

extension SendWithSwapFlowFactory: SendGenericFlowFactory {
    func make(router: any SendRoutable) -> SendViewModel {
        let amount = makeSendAmountStep()
        let destination = makeSendDestinationStep(router: router)
        let fee = makeSendFeeStep(router: router)
        let providers = makeSwapProviders()

        let summary = makeSendSummaryStep(
            sendDestinationCompactViewModel: destination.compact,
            sendAmountCompactViewModel: amount.compact,
            sendFeeCompactViewModel: fee.compact
        )

        let finish = makeSendFinishStep(
            sendAmountFinishViewModel: amount.finish,
            sendDestinationCompactViewModel: destination.compact,
            sendFeeFinishViewModel: fee.finish,
            router: router
        )

        // Model setup
        // We have to set dependencies here after all setups is completed
        sendWithSwapModel.externalDestinationUpdater = destination.externalUpdater

        // Forward external updaters to internal models
        transferModel.externalAmountUpdater = amount.amountUpdater
        transferModel.externalDestinationUpdater = destination.externalUpdater
        transferModel.informationRelevanceService = CommonInformationRelevanceService(
            input: sendWithSwapModel, provider: sendWithSwapModel
        )

        swapModel.externalAmountUpdater = amount.amountUpdater

        // Steps setup
        fee.compact.bind(input: sendWithSwapModel)
        fee.finish.bind(input: sendWithSwapModel)

        // Notifications setup
        sendNotificationManager.setup(input: transferModel)
        sendNotificationManager.setupManager(with: transferModel)

        swapNotificationManager.setupManager(with: sendWithSwapModel)
        swapNotificationManager.setup(
            sourceTokenInput: swapModel,
            receiveTokenInput: swapModel,
            swapModelStateProvider: swapModel
        )

        // Logger setup
        analyticsLogger.setup(sendDestinationInput: sendWithSwapModel)
        analyticsLogger.setup(sendFeeInput: sendWithSwapModel)
        analyticsLogger.setup(sendSourceTokenInput: sendWithSwapModel)
        analyticsLogger.setup(sendReceiveTokenInput: sendWithSwapModel)
        analyticsLogger.setup(sendSwapProvidersInput: sendWithSwapModel)

        let sendReceiveTokensListBuilder = SendReceiveTokensListBuilder(
            userWalletInfo: userWalletInfo,
            sourceTokenInput: sendWithSwapModel,
            receiveTokenOutput: sendWithSwapModel,
            receiveTokenBuilder: makeSendReceiveTokenBuilder(),
            analyticsLogger: analyticsLogger
        )

        let stepsManager = CommonSendStepsManager(
            amountStep: amount.step,
            destinationStep: destination.step,
            summaryStep: summary,
            finishStep: finish,
            feeSelectorBuilder: fee.feeSelectorBuilder,
            receiveTokensListBuilder: sendReceiveTokensListBuilder,
            providersSelector: providers.selector,
            summaryTitleProvider: SendWithSwapSummaryTitleProvider(receiveTokenInput: sendWithSwapModel),
            confirmTransactionPolicy: CommonConfirmTransactionPolicy(userWalletInfo: userWalletInfo),
            router: router
        )

        let viewModel = makeSendBase(stepsManager: stepsManager, router: router)

        amount.step.set(router: stepsManager)
        destination.step.set(stepRouter: stepsManager)
        summary.set(router: stepsManager)

        sendWithSwapModel.router = viewModel
        sendWithSwapModel.alertPresenter = viewModel

        return viewModel
    }
}

// MARK: - SendBaseBuildable

extension SendWithSwapFlowFactory: SendBaseBuildable {
    var baseIO: SendViewModelBuilder.IO {
        SendViewModelBuilder.IO(input: sendWithSwapModel, output: sendWithSwapModel)
    }

    var baseDependencies: SendViewModelBuilder.Dependencies {
        SendViewModelBuilder.Dependencies(
            alertBuilder: makeSendAlertBuilder(),
            mailDataBuilder: CommonSendMailDataBuilder(
                baseDataInput: sendWithSwapModel,
                sourceTokenInput: sendWithSwapModel
            ),
            approveViewModelInputDataBuilder: CommonSendApproveViewModelInputDataBuilder(
                sourceTokenInput: sendWithSwapModel,
                approveDataInput: sendWithSwapModel
            ),
            feeCurrencyProviderDataBuilder: CommonSendFeeCurrencyProviderDataBuilder(
                sourceTokenInput: sendWithSwapModel
            ),
            analyticsLogger: analyticsLogger,
            blockchainSDKNotificationMapper: BlockchainSDKNotificationMapper(tokenItem: tokenItem),
            tangemIconProvider: CommonTangemIconProvider(config: userWalletInfo.config)
        )
    }
}

// MARK: - SendAmountStepBuildable

extension SendWithSwapFlowFactory: SendAmountStepBuildable {
    var amountIO: SendAmountStepBuilder.IO {
        SendAmountStepBuilder.IO(
            sourceIO: (input: sendWithSwapModel, output: sendWithSwapModel),
            sourceAmountIO: (input: sendWithSwapModel, output: sendWithSwapModel),
            receiveIO: (input: sendWithSwapModel, output: sendWithSwapModel),
            receiveAmountIO: (input: sendWithSwapModel, output: sendWithSwapModel),
            swapProvidersInput: sendWithSwapModel,
        )
    }

    var amountTypes: SendAmountStepBuilder.Types {
        .init(initialSourceToken: sourceToken, flowActionType: .send)
    }

    var amountDependencies: SendAmountStepBuilder.Dependencies {
        SendAmountStepBuilder.Dependencies(
            sendAmountValidator: CommonSendAmountValidator(input: sendWithSwapModel),
            amountModifier: .none,
            notificationService: notificationManager as? SendAmountNotificationService,
            analyticsLogger: analyticsLogger,
            isFixedRateMode: isFixedRateMode
        )
    }
}

// MARK: - SendDestinationStepBuildable

extension SendWithSwapFlowFactory: SendDestinationStepBuildable {
    var destinationIO: SendDestinationStepBuilder.IO {
        SendDestinationStepBuilder.IO(
            input: sendWithSwapModel,
            output: sendWithSwapModel,
            receiveTokenInput: sendWithSwapModel,
            destinationAccountOutput: sendWithSwapModel
        )
    }

    var destinationTypes: SendDestinationStepBuilder.Types {
        .init(initialSourceToken: sourceToken)
    }

    var destinationDependencies: SendDestinationStepBuilder.Dependencies {
        SendDestinationStepBuilder.Dependencies(
            sendQRCodeService: makeSendQRCodeService(),
            analyticsLogger: analyticsLogger,
            destinationInteractorDependenciesProvider: SendDestinationInteractorDependenciesProvider(
                sourceToken: sourceToken,
                receivedToken: sendWithSwapModel.receiveToken.value,
                analyticsLogger: analyticsLogger,
                receiveTokenWalletDataProvider: SendReceiveTokenWalletDataProvider()
            )
        )
    }
}

// MARK: - SendFeeStepBuildable

extension SendWithSwapFlowFactory: SendFeeStepBuildable {
    var feeDependencies: SendFeeStepBuilder.Dependencies {
        SendFeeStepBuilder.Dependencies(
            tokenFeeManagerProviding: sendWithSwapModel,
            feeSelectorOutput: sendWithSwapModel,
            analyticsLogger: analyticsLogger
        )
    }
}

// MARK: - SendSwapProvidersBuildable

extension SendWithSwapFlowFactory: SendSwapProvidersBuildable {
    var swapProvidersIO: SendSwapProvidersBuilder.IO {
        SendSwapProvidersBuilder.IO(input: sendWithSwapModel, output: sendWithSwapModel, sourceTokenInput: sendWithSwapModel, receiveTokenInput: sendWithSwapModel)
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

// MARK: - SendSummaryStepBuildable

extension SendWithSwapFlowFactory: SendSummaryStepBuildable {
    var summaryIO: SendSummaryStepBuilder.IO {
        SendSummaryStepBuilder.IO(input: sendWithSwapModel, output: sendWithSwapModel, swapModelStateProvider: swapModel)
    }

    var summaryTypes: SendSummaryStepBuilder.Types {
        .init(settings: .init(destinationEditableType: .editable, amountEditableType: .editable))
    }

    var summaryDependencies: SendSummaryStepBuilder.Dependencies {
        SendSummaryStepBuilder.Dependencies(
            sendFeeProvider: sendWithSwapModel,
            notificationManager: notificationManager,
            analyticsLogger: analyticsLogger,
            sendDescriptionBuilder: makeSendTransactionSummaryDescriptionBuilder(),
            sendWithSwapDescriptionBuilder: makeSendWithSwapTransactionSummaryDescriptionBuilder(),
            stakingDescriptionBuilder: makeStakingTransactionSummaryDescriptionBuilder(),
        )
    }
}

// MARK: - SendFinishStepBuildable

extension SendWithSwapFlowFactory: SendFinishStepBuildable {
    var finishIO: SendFinishStepBuilder.IO {
        SendFinishStepBuilder.IO(input: sendWithSwapModel)
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
