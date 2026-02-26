//
//  SellFlowFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct TangemUI.TokenIconInfo

class SellFlowFactory: SendWithSwapFlowBaseDependenciesFactory {
    var transferableToken: SendTransferableToken { sourceToken }
    var tokenItem: TokenItem { transferableToken.tokenItem }

    let sourceToken: SendWithSwapToken
    let sellParameters: PredefinedSellParameters
    let expressDependenciesFactory: ExpressDependenciesFactory
    let expressInteractorFactory: ExpressInteractorFactory

    lazy var analyticsLogger: SendAnalyticsLogger = makeSendAnalyticsLogger(sendType: .send)
    lazy var swapManager = makeSwapManager(expressInteractor: expressInteractorFactory.expressInteractor)
    lazy var sendModel = makeSendModel(
        sourceToken: sourceToken,
        swapManager: swapManager,
        analyticsLogger: analyticsLogger,
        predefinedValues: mapToPredefinedValues(sellParameters: sellParameters)
    )

    lazy var notificationManager = makeSendWithSwapNotificationManager(
        receiveTokenInput: sendModel,
        expressInteractor: expressInteractorFactory.expressInteractor
    )

    init(
        sourceToken: SendWithSwapToken,
        sellParameters: PredefinedSellParameters,
        source: ExpressInteractorWalletModelWrapper
    ) {
        self.sourceToken = sourceToken
        self.sellParameters = sellParameters

        let expressDependenciesInput = ExpressDependenciesInput(
            userWalletInfo: sourceToken.userWalletInfo,
            source: source,
            destination: .none
        )

        expressDependenciesFactory = CommonExpressDependenciesFactory(userWalletInfo: sourceToken.userWalletInfo)
        expressInteractorFactory = ExpressInteractorFactory(
            input: expressDependenciesInput,
            expressDependenciesFactory: expressDependenciesFactory
        )
    }

    private func mapToPredefinedValues(sellParameters: PredefinedSellParameters?) -> SendModel.PredefinedValues {
        let destination = sellParameters.map { SendDestination(value: .plain($0.destination), source: .sellProvider) }
        let amount = sellParameters.map { sellParameters in
            let fiatValue = tokenItem.currencyId.flatMap { currencyId in
                BalanceConverter().convertToFiat(sellParameters.amount, currencyId: currencyId)
            }

            return SendAmount(type: .typical(crypto: sellParameters.amount, fiat: fiatValue))
        }

        // the additionalField is required. Other can be optional
        let additionalField: SendDestinationAdditionalField = {
            guard let type = SendDestinationAdditionalFieldType.type(for: tokenItem.blockchain) else {
                return .notSupported
            }

            guard let tag = sellParameters?.tag?.nilIfEmpty,
                  let params = try? makeTransactionParametersBuilder().transactionParameters(value: tag) else {
                return .empty(type: type)
            }

            return .filled(type: type, value: tag, params: params)
        }()

        return SendModel.PredefinedValues(destination: destination, tag: additionalField, amount: amount)
    }
}

// MARK: - SendGenericFlowFactory

extension SellFlowFactory: SendGenericFlowFactory {
    func make(router: any SendRoutable) -> SendViewModel {
        let sendDestinationCompactViewModel = SendDestinationCompactViewModel(
            input: sendModel
        )

        let sendAmountCompactViewModel = SendAmountCompactViewModel(
            initialSourceToken: sourceToken,
            actionType: .send,
            sourceTokenInput: sendModel,
            sourceTokenAmountInput: sendModel,
            receiveTokenInput: sendModel,
            receiveTokenAmountInput: sendModel,
            swapProvidersInput: sendModel
        )

        let sendAmountFinishViewModel = SendAmountFinishViewModel(
            flowActionType: .send,
            sourceTokenInput: sendModel,
            sourceTokenAmountInput: sendModel,
            receiveTokenInput: sendModel,
            receiveTokenAmountInput: sendModel,
            swapProvidersInput: sendModel
        )

        let fee = makeSendFeeStep(router: router)

        // Destination .disable
        // Amount .disable
        let summary = makeSendSummaryStep(
            sendDestinationCompactViewModel: sendDestinationCompactViewModel,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            sendFeeCompactViewModel: fee.compact
        )

        let finish = makeSendFinishStep(
            sendAmountFinishViewModel: sendAmountFinishViewModel,
            sendDestinationCompactViewModel: sendDestinationCompactViewModel,
            sendFeeFinishViewModel: fee.finish,
            router: router
        )

        // Model setup
        // We have to set dependencies here after all setups is completed
        sendModel.informationRelevanceService = CommonInformationRelevanceService(
            input: sendModel, provider: sendModel
        )

        // Update the fees in case we in the sell flow
        sendModel.updateFees()

        // Steps setup
        fee.compact.bind(input: sendModel)
        fee.finish.bind(input: sendModel)

        // Notifications setup
        notificationManager.setup(input: sendModel)
        notificationManager.setupManager(with: sendModel)

        // Logger setup
        analyticsLogger.setup(sendDestinationInput: sendModel)
        analyticsLogger.setup(sendFeeInput: sendModel)
        analyticsLogger.setup(sendSourceTokenInput: sendModel)
        analyticsLogger.setup(sendReceiveTokenInput: sendModel)
        analyticsLogger.setup(sendSwapProvidersInput: sendModel)

        let stepsManager = CommonSellStepsManager(
            feeSelectorBuilder: fee.feeSelectorBuilder,
            summaryStep: summary,
            finishStep: finish,
            confirmTransactionPolicy: CommonConfirmTransactionPolicy(userWalletInfo: userWalletInfo)
        )

        let viewModel = makeSendBase(stepsManager: stepsManager, router: router)

        summary.set(router: stepsManager)

        sendModel.router = viewModel
        sendModel.alertPresenter = viewModel

        return viewModel
    }
}

// MARK: - SendBaseBuildable

extension SellFlowFactory: SendBaseBuildable {
    var baseIO: SendViewModelBuilder.IO {
        SendViewModelBuilder.IO(input: sendModel, output: sendModel)
    }

    var baseDependencies: SendViewModelBuilder.Dependencies {
        SendViewModelBuilder.Dependencies(
            alertBuilder: makeSendAlertBuilder(),
            mailDataBuilder: CommonSendMailDataBuilder(
                baseDataInput: sendModel,
                emailDataCollectorBuilder: sourceToken.emailDataCollectorBuilder,
                emailDataProvider: sourceToken.userWalletInfo.emailDataProvider,
            ),
            approveViewModelInputDataBuilder: CommonSendApproveViewModelInputDataBuilder(
                sourceToken: sourceToken,
                approveDataInput: swapManager
            ),
            feeCurrencyProviderDataBuilder: CommonSendFeeCurrencyProviderDataBuilder(
                sourceToken: sourceToken
            ),
            analyticsLogger: analyticsLogger,
            blockchainSDKNotificationMapper: BlockchainSDKNotificationMapper(tokenItem: tokenItem),
            tangemIconProvider: CommonTangemIconProvider(config: userWalletInfo.config)
        )
    }
}

// MARK: - SendFeeStepBuildable

extension SellFlowFactory: SendFeeStepBuildable {
    var feeDependencies: SendFeeStepBuilder.Dependencies {
        SendFeeStepBuilder.Dependencies(
            tokenFeeManagerProviding: sendModel,
            feeSelectorOutput: sendModel,
            analyticsLogger: analyticsLogger
        )
    }
}

// MARK: - SendSummaryStepBuildable

extension SellFlowFactory: SendSummaryStepBuildable {
    var summaryIO: SendSummaryStepBuilder.IO {
        SendSummaryStepBuilder.IO(input: sendModel, output: sendModel, receiveTokenAmountInput: sendModel)
    }

    var summaryTypes: SendSummaryStepBuilder.Types {
        .init(settings: .init(destinationEditableType: .noEditable, amountEditableType: .noEditable))
    }

    var summaryDependencies: SendSummaryStepBuilder.Dependencies {
        SendSummaryStepBuilder.Dependencies(
            sendFeeProvider: sendModel,
            notificationManager: notificationManager,
            analyticsLogger: analyticsLogger,
            sendDescriptionBuilder: makeSendTransactionSummaryDescriptionBuilder(),
            sendWithSwapDescriptionBuilder: makeSendWithSwapTransactionSummaryDescriptionBuilder(),
            stakingDescriptionBuilder: makeStakingTransactionSummaryDescriptionBuilder(),
        )
    }
}

// MARK: - SendFinishStepBuildable

extension SellFlowFactory: SendFinishStepBuildable {
    var finishIO: SendFinishStepBuilder.IO {
        SendFinishStepBuilder.IO(input: sendModel)
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
