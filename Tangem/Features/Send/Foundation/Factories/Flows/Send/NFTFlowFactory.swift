//
//  NFTFlowFactory 2.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct TangemUI.TokenIconInfo

class NFTFlowFactory: SendFlowBaseDependenciesFactory {
    let userWalletInfo: UserWalletInfo
    let tokenItem: TokenItem
    let feeTokenItem: TokenItem
    let tokenIconInfo: TokenIconInfo
    let accountModelAnalyticsProvider: (any AccountModelAnalyticsProviding)?
    let nftAssetStepBuilder: NFTAssetStepBuilder
    let tokenHeaderProvider: SendGenericTokenHeaderProvider

    let walletAddresses: [String]
    let suggestedWallets: [SendDestinationSuggestedWallet]

    let walletModelHistoryUpdater: any WalletModelHistoryUpdater
    let tokenFeeLoader: any TokenFeeLoader
    let walletModelDependenciesProvider: WalletModelDependenciesProvider
    let availableBalanceProvider: any TokenBalanceProvider
    let fiatAvailableBalanceProvider: any TokenBalanceProvider
    let transactionDispatcherFactory: TransactionDispatcherFactory
    let baseDataBuilderFactory: SendBaseDataBuilderFactory
    let expressDependenciesFactory: ExpressDependenciesFactory

    let analyticsLogger: SendAnalyticsLogger

    lazy var swapManager = makeSwapManager()
    lazy var sendModel = makeSendWithSwapModel(
        swapManager: swapManager,
        analyticsLogger: analyticsLogger,
        predefinedValues: .init(
            amount: .init(type: .typical(crypto: NFTSendUtil.amountToSend, fiat: .none))
        )
    )

    lazy var notificationManager = makeSendWithSwapNotificationManager(receiveTokenInput: sendModel)
    lazy var customFeeService = makeCustomFeeService(input: sendModel)
    lazy var sendFeeProvider = makeSendWithSwapFeeProvider(
        receiveTokenInput: sendModel,
        sendFeeProvider: makeTokenFeeProvider(input: sendModel, output: sendModel, feeProviderInput: sendModel, customFeeProvider: customFeeService),
        swapFeeProvider: makeSwapFeeProvider(swapManager: swapManager)
    )

    init(
        userWalletInfo: UserWalletInfo,
        nftAssetStepBuilder: NFTAssetStepBuilder,
        walletModel: any WalletModel
    ) {
        self.userWalletInfo = userWalletInfo
        self.nftAssetStepBuilder = nftAssetStepBuilder
        tokenHeaderProvider = SendTokenHeaderProvider(
            userWalletInfo: userWalletInfo,
            account: walletModel.account,
            flowActionType: .send
        )

        tokenItem = walletModel.tokenItem
        feeTokenItem = walletModel.feeTokenItem
        tokenIconInfo = TokenIconInfoBuilder().build(
            from: walletModel.tokenItem,
            isCustom: walletModel.isCustom
        )
        accountModelAnalyticsProvider = walletModel.account
        walletAddresses = walletModel.addresses.map(\.value)

        suggestedWallets = SendSuggestedWalletsFactory().makeSuggestedWallets(walletModel: walletModel)
        analyticsLogger = Self.makeSendAnalyticsLogger(walletModel: walletModel, sendType: .nft)

        walletModelHistoryUpdater = walletModel
        tokenFeeLoader = walletModel.tokenFeeLoader
        walletModelDependenciesProvider = walletModel
        availableBalanceProvider = walletModel.availableBalanceProvider
        fiatAvailableBalanceProvider = walletModel.fiatAvailableBalanceProvider
        transactionDispatcherFactory = TransactionDispatcherFactory(
            walletModel: walletModel,
            signer: userWalletInfo.signer
        )
        baseDataBuilderFactory = SendBaseDataBuilderFactory(
            walletModel: walletModel,
            userWalletInfo: userWalletInfo
        )

        let source = ExpressInteractorWalletModelWrapper(
            userWalletInfo: userWalletInfo,
            walletModel: walletModel,
            expressOperationType: .swapAndSend
        )

        let expressDependenciesInput = ExpressDependenciesInput(
            userWalletInfo: userWalletInfo,
            source: source,
            destination: .none
        )

        expressDependenciesFactory = CommonExpressDependenciesFactory(input: expressDependenciesInput)
    }
}

// MARK: - SendGenericFlowFactory

extension NFTFlowFactory: SendGenericFlowFactory {
    func make(router: any SendRoutable) -> SendViewModel {
        let header = tokenHeaderProvider.makeSendTokenHeader()
        let nftAssetCompactViewModel = nftAssetStepBuilder.makeNFTAssetCompactViewModel(header: header)
        let destination = makeSendDestinationStep(router: router)
        let fee = makeSendFeeStep(router: router)

        // Destination editable
        // Amount noEditable
        let summary = makeSendSummaryStep(
            sendDestinationCompactViewModel: destination.compact,
            nftAssetCompactViewModel: nftAssetCompactViewModel,
            sendFeeCompactViewModel: fee.compact
        )

        let finish = makeSendFinishStep(
            nftAssetCompactViewModel: nftAssetCompactViewModel,
            sendDestinationCompactViewModel: destination.compact,
            sendFeeFinishViewModel: fee.finish,
            router: router
        )

        // Model setup
        // We have to set dependencies here after all setups is completed
        sendModel.sendFeeProvider = sendFeeProvider
        sendModel.informationRelevanceService = CommonInformationRelevanceService(
            input: sendModel, output: sendModel, provider: sendFeeProvider
        )

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

        let stepsManager = CommonNFTSendStepsManager(
            destinationStep: destination.step,
            feeSelector: fee.feeSelector,
            summaryStep: summary,
            finishStep: finish,
            summaryTitleProvider: SendWithSwapSummaryTitleProvider(receiveTokenInput: sendModel),
            router: router
        )

        let viewModel = makeSendBase(stepsManager: stepsManager, router: router)

        destination.step.set(stepRouter: stepsManager)
        summary.set(router: stepsManager)

        sendModel.router = viewModel
        sendModel.alertPresenter = viewModel

        return viewModel
    }
}

// MARK: - SendBaseBuildable

extension NFTFlowFactory: SendBaseBuildable {
    var baseIO: SendViewModelBuilder.IO {
        SendViewModelBuilder.IO(input: sendModel, output: sendModel)
    }

    var baseDependencies: SendViewModelBuilder.Dependencies {
        SendViewModelBuilder.Dependencies(
            alertBuilder: makeSendAlertBuilder(),
            dataBuilder: baseDataBuilderFactory.makeSendBaseDataBuilder(
                baseDataInput: sendModel,
                approveDataInput: swapManager,
                sendReceiveTokensListBuilder: SendReceiveTokensListBuilder(
                    userWalletInfo: userWalletInfo,
                    sourceTokenInput: sendModel,
                    receiveTokenOutput: sendModel,
                    receiveTokenBuilder: makeSendReceiveTokenBuilder(),
                    analyticsLogger: analyticsLogger
                )
            ),
            analyticsLogger: analyticsLogger,
            blockchainSDKNotificationMapper: makeBlockchainSDKNotificationMapper(),
            tangemIconProvider: CommonTangemIconProvider(config: userWalletInfo.config)
        )
    }
}

// MARK: - SendDestinationStepBuildable

extension NFTFlowFactory: SendDestinationStepBuildable {
    var destinationIO: SendDestinationStepBuilder.IO {
        SendDestinationStepBuilder.IO(
            input: sendModel,
            output: sendModel,
            receiveTokenInput: sendModel,
            destinationAccountOutput: sendModel
        )
    }

    var destinationDependencies: SendDestinationStepBuilder.Dependencies {
        SendDestinationStepBuilder.Dependencies(
            sendQRCodeService: makeSendQRCodeService(),
            analyticsLogger: analyticsLogger,
            destinationInteractorDependenciesProvider: makeSendDestinationInteractorDependenciesProvider(
                receiveTokenInput: sendModel,
                analyticsLogger: analyticsLogger
            ),
        )
    }

    private func makeSendDestinationInteractorDependenciesProvider(
        receiveTokenInput: SendReceiveTokenInput,
        analyticsLogger: any SendDestinationAnalyticsLogger
    ) -> SendDestinationInteractorDependenciesProvider {
        SendDestinationInteractorDependenciesProvider(
            receivedTokenType: receiveTokenInput.receiveToken,
            sendingWalletData: .init(
                walletAddresses: walletAddresses,
                suggestedWallets: suggestedWallets,
                destinationTransactionHistoryProvider: CommonSendDestinationTransactionHistoryProvider(
                    transactionHistoryUpdater: walletModelHistoryUpdater,
                    transactionHistoryMapper: TransactionHistoryMapper(
                        currencySymbol: tokenItem.currencySymbol,
                        walletAddresses: walletAddresses,
                        showSign: false,
                        isToken: tokenItem.isToken
                    )
                ),
                analyticsLogger: analyticsLogger
            )
        )
    }
}

// MARK: - SendFeeStepBuildable

extension NFTFlowFactory: SendFeeStepBuildable {
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
            customFeeProvider: customFeeService
        )
    }
}

// MARK: - SendSummaryStepBuildable

extension NFTFlowFactory: SendSummaryStepBuildable {
    var summaryIO: SendSummaryStepBuilder.IO {
        SendSummaryStepBuilder.IO(input: sendModel, output: sendModel, receiveTokenAmountInput: sendModel)
    }

    var summaryTypes: SendSummaryStepBuilder.Types {
        .init(settings: .init(destinationEditableType: .editable, amountEditableType: .noEditable))
    }

    var summaryDependencies: SendSummaryStepBuilder.Dependencies {
        SendSummaryStepBuilder.Dependencies(
            sendFeeProvider: sendFeeProvider,
            notificationManager: notificationManager,
            analyticsLogger: analyticsLogger,
            sendDescriptionBuilder: makeSendTransactionSummaryDescriptionBuilder(),
            swapDescriptionBuilder: makeSwapTransactionSummaryDescriptionBuilder(),
            stakingDescriptionBuilder: makeStakingTransactionSummaryDescriptionBuilder(),
        )
    }
}

// MARK: - SendFinishStepBuildable

extension NFTFlowFactory: SendFinishStepBuildable {
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
