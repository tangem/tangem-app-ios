//
//  NFTFlowFactory 2.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct TangemUI.TokenIconInfo

class NFTFlowFactory: SendFlowBaseDependenciesFactory {
    let tokenItem: TokenItem
    let feeTokenItem: TokenItem
    let tokenIconInfo: TokenIconInfo
    let nftAssetStepBuilder: NFTAssetStepBuilder
    let userWalletInfo: UserWalletInfo

    let walletAddresses: [String]
    let suggestedWallets: [SendDestinationSuggestedWallet]
    let shouldShowFeeSelector: Bool

    let walletModelHistoryUpdater: any WalletModelHistoryUpdater
    let walletModelFeeProvider: any WalletModelFeeProvider
    let walletModelDependenciesProvider: WalletModelDependenciesProvider
    let walletModelBalancesProvider: WalletModelBalancesProvider
    let transactionDispatcherFactory: TransactionDispatcherFactory
    let baseDataBuilderFactory: SendBaseDataBuilderFactory
    let expressDependenciesFactory: ExpressDependenciesFactory

    lazy var swapManager = makeSwapManager()
    lazy var analyticsLogger = makeSendAnalyticsLogger(sendType: .nft)
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
        sendFeeProvider: makeSendFeeProvider(input: sendModel, hasCustomFeeService: customFeeService != nil),
        swapFeeProvider: makeSwapFeeProvider(swapManager: swapManager)
    )

    init(
        userWalletInfo: UserWalletInfo,
        nftAssetStepBuilder: NFTAssetStepBuilder,
        walletModel: any WalletModel,
        expressInput: CommonExpressDependenciesFactory.Input
    ) {
        self.userWalletInfo = userWalletInfo
        self.nftAssetStepBuilder = nftAssetStepBuilder

        tokenItem = walletModel.tokenItem
        feeTokenItem = walletModel.feeTokenItem
        tokenIconInfo = TokenIconInfoBuilder().build(
            from: walletModel.tokenItem,
            isCustom: walletModel.isCustom
        )
        walletAddresses = walletModel.addresses.map(\.value)
        suggestedWallets = SendSuggestedWalletsFactory().makeSuggestedWallets(
            walletModel: walletModel
        )
        shouldShowFeeSelector = walletModel.shouldShowFeeSelector
        walletModelHistoryUpdater = walletModel
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
}

// MARK: - SendGenericFlowFactory

extension NFTFlowFactory: SendGenericFlowFactory {
    func make(router: any SendRoutable) -> SendViewModel {
        let nftAssetCompactViewModel = nftAssetStepBuilder.makeNFTAssetCompactViewModel()
        let destination = makeSendDestinationStep(router: router)
        let fee = makeSendFeeStep()

        // Destination editable
        // Amount noEditable
        let summary = makeSendNewSummaryStep(
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

// MARK: - SendDestinationStepBuildable

extension NFTFlowFactory: SendDestinationStepBuildable {
    var destinationIO: SendDestinationStepBuilder.IO {
        SendDestinationStepBuilder.IO(input: sendModel, output: sendModel, receiveTokenInput: sendModel)
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
                        showSign: false
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
            customFeeService: customFeeService
        )
    }
}

// MARK: - SendNewSummaryStepBuildable

extension NFTFlowFactory: SendNewSummaryStepBuildable {
    var newSummaryIO: SendNewSummaryStepBuilder.IO {
        SendNewSummaryStepBuilder.IO(input: sendModel, output: sendModel, receiveTokenAmountInput: sendModel)
    }

    var newSummaryTypes: SendNewSummaryStepBuilder.Types {
        .init(settings: .init(destinationEditableType: .editable, amountEditableType: .noEditable))
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

extension NFTFlowFactory: SendNewFinishStepBuildable {
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
