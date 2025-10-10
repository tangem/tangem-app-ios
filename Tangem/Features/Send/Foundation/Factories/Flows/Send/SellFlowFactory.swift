//
//  SellFlowFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct TangemUI.TokenIconInfo

class SellFlowFactory: SendFlowBaseDependenciesFactory {
    let tokenItem: TokenItem
    let feeTokenItem: TokenItem
    let tokenIconInfo: TokenIconInfo
    let userWalletInfo: SendWalletInfo
    let sellParameters: PredefinedSellParameters

    let shouldShowFeeSelector: Bool

    let walletModelFeeProvider: any WalletModelFeeProvider
    let walletModelDependenciesProvider: any WalletModelDependenciesProvider
    let walletModelBalancesProvider: any WalletModelBalancesProvider
    let transactionDispatcherFactory: TransactionDispatcherFactory
    let baseDataBuilderFactory: SendBaseDataBuilderFactory
    let expressDependenciesFactory: any ExpressDependenciesFactory

    lazy var swapManager = makeSwapManager()
    lazy var analyticsLogger = makeSendAnalyticsLogger(sendType: .sell)
    lazy var sendModel = makeSendWithSwapModel(
        swapManager: swapManager,
        analyticsLogger: analyticsLogger,
        predefinedValues: mapToPredefinedValues(sellParameters: sellParameters)
    )

    lazy var notificationManager = makeSendWithSwapNotificationManager(receiveTokenInput: sendModel)
    lazy var customFeeService = makeCustomFeeService(input: sendModel)
    lazy var sendFeeProvider = makeSendWithSwapFeeProvider(
        receiveTokenInput: sendModel,
        sendFeeProvider: makeSendFeeProvider(input: sendModel, hasCustomFeeService: customFeeService != nil),
        swapFeeProvider: makeSwapFeeProvider(swapManager: swapManager)
    )

    init(
        userWalletInfo: SendWalletInfo,
        sellParameters: PredefinedSellParameters,
        walletModel: any WalletModel,
        expressInput: CommonExpressDependenciesFactory.Input
    ) {
        self.userWalletInfo = userWalletInfo
        self.sellParameters = sellParameters

        tokenItem = walletModel.tokenItem
        feeTokenItem = walletModel.feeTokenItem
        tokenIconInfo = TokenIconInfoBuilder().build(
            from: walletModel.tokenItem,
            isCustom: walletModel.isCustom
        )

        shouldShowFeeSelector = walletModel.shouldShowFeeSelector
        walletModelFeeProvider = walletModel
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
        expressDependenciesFactory = CommonExpressDependenciesFactory(
            input: expressInput,
            initialWallet: walletModel.asExpressInteractorWallet,
            destinationWallet: .none,
            // We support only `CEX` in `Send With Swap` flow
            supportedProviderTypes: [.cex],
            operationType: .swapAndSend
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

        let sendAmountCompactViewModel = SendNewAmountCompactViewModel(
            sourceTokenInput: sendModel,
            sourceTokenAmountInput: sendModel,
            receiveTokenInput: sendModel,
            receiveTokenAmountInput: sendModel,
            swapProvidersInput: sendModel
        )

        let sendAmountFinishViewModel = SendNewAmountFinishViewModel(
            sourceTokenInput: sendModel,
            sourceTokenAmountInput: sendModel,
            receiveTokenInput: sendModel,
            receiveTokenAmountInput: sendModel,
            swapProvidersInput: sendModel
        )

        let fee = makeSendFeeStep()

        // Destination .disable
        // Amount .disable
        let summary = makeSendNewSummaryStep(
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
        sendModel.sendFeeProvider = sendFeeProvider
        sendModel.informationRelevanceService = CommonInformationRelevanceService(
            input: sendModel, output: sendModel, provider: sendFeeProvider
        )

        // Update the fees in case we in the sell flow
        sendFeeProvider.updateFees()

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
            feeSelector: fee.feeSelector,
            summaryStep: summary,
            finishStep: finish,
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
            dataBuilder: baseDataBuilderFactory.makeSendBaseDataBuilder(
                input: sendModel,
                sendReceiveTokensListBuilder: SendReceiveTokensListBuilder(
                    sourceTokenInput: sendModel,
                    receiveTokenOutput: sendModel,
                    expressRepository: expressDependenciesFactory.expressRepository,
                    receiveTokenBuilder: makeSendReceiveTokenBuilder(),
                    analyticsLogger: analyticsLogger
                )
            ),
            analyticsLogger: analyticsLogger,
            blockchainSDKNotificationMapper: makeBlockchainSDKNotificationMapper()
        )
    }
}

// MARK: - SendFeeStepBuildable

extension SellFlowFactory: SendFeeStepBuildable {
    var feeIO: SendNewFeeStepBuilder.IO {
        SendNewFeeStepBuilder.IO(input: sendModel, output: sendModel)
    }

    var feeTypes: SendNewFeeStepBuilder.Types {
        SendNewFeeStepBuilder.Types(
            feeTokenItem: feeTokenItem,
            isFeeApproximate: isFeeApproximate()
        )
    }

    var feeDependencies: SendNewFeeStepBuilder.Dependencies {
        SendNewFeeStepBuilder.Dependencies(
            feeProvider: sendFeeProvider,
            analyticsLogger: analyticsLogger,
            customFeeService: customFeeService
        )
    }
}

// MARK: - SendNewSummaryStepBuildable

extension SellFlowFactory: SendNewSummaryStepBuildable {
    var newSummaryIO: SendNewSummaryStepBuilder.IO {
        SendNewSummaryStepBuilder.IO(input: sendModel, output: sendModel, receiveTokenAmountInput: sendModel)
    }

    var newSummaryTypes: SendNewSummaryStepBuilder.Types {
        .init(settings: .init(destinationEditableType: .noEditable, amountEditableType: .noEditable))
    }

    var newSummaryDependencies: SendNewSummaryStepBuilder.Dependencies {
        SendNewSummaryStepBuilder.Dependencies(
            sendFeeProvider: sendFeeProvider,
            notificationManager: notificationManager,
            analyticsLogger: analyticsLogger,
            sendDescriptionBuilder: makeSendTransactionSummaryDescriptionBuilder(),
            swapDescriptionBuilder: makeSwapTransactionSummaryDescriptionBuilder()
        )
    }
}

// MARK: - SendNewFinishStepBuildable

extension SellFlowFactory: SendNewFinishStepBuildable {
    var newFinishIO: SendNewFinishStepBuilder.IO {
        SendNewFinishStepBuilder.IO(input: sendModel)
    }

    var newFinishTypes: SendNewFinishStepBuilder.Types {
        SendNewFinishStepBuilder.Types(tokenItem: tokenItem)
    }

    var newFinishDependencies: SendNewFinishStepBuilder.Dependencies {
        SendNewFinishStepBuilder.Dependencies(
            analyticsLogger: analyticsLogger,
        )
    }
}
