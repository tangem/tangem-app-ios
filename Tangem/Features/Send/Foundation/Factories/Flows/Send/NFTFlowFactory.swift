//
//  NFTFlowFactory 2.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct TangemUI.TokenIconInfo

class NFTFlowFactory: SendFlowBaseDependenciesFactory {
    let sourceToken: SendSourceToken
    let nftAssetStepBuilder: NFTAssetStepBuilder
    let sendingWalletDestinationStepDataInput: SendDestinationInteractorDependenciesProvider.SendingWalletDataInput
    let baseDataBuilderFactory: SendBaseDataBuilderFactory
    let expressDependenciesFactory: ExpressDependenciesFactory

    lazy var analyticsLogger: SendAnalyticsLogger = makeSendAnalyticsLogger(sendType: .send)
    lazy var swapManager = makeSwapManager()
    lazy var sendModel = makeSendWithSwapModel(
        swapManager: swapManager,
        analyticsLogger: analyticsLogger,
        predefinedValues: .init(
            amount: .init(type: .typical(crypto: NFTSendUtil.amountToSend, fiat: .none))
        )
    )

    lazy var notificationManager = makeSendWithSwapNotificationManager(receiveTokenInput: sendModel)

    init(
        sourceToken: SendSourceToken,
        nftAssetStepBuilder: NFTAssetStepBuilder,
        sendingWalletDestinationStepDataInput: SendDestinationInteractorDependenciesProvider.SendingWalletDataInput,
        baseDataBuilderFactory: SendBaseDataBuilderFactory,
        source: ExpressInteractorWalletModelWrapper
    ) {
        self.sourceToken = sourceToken
        self.nftAssetStepBuilder = nftAssetStepBuilder
        self.sendingWalletDestinationStepDataInput = sendingWalletDestinationStepDataInput
        self.baseDataBuilderFactory = baseDataBuilderFactory

        let expressDependenciesInput = ExpressDependenciesInput(
            userWalletInfo: sourceToken.userWalletInfo,
            source: source,
            destination: .none
        )

        expressDependenciesFactory = CommonExpressDependenciesFactory(input: expressDependenciesInput)
    }
}

// MARK: - SendGenericFlowFactory

extension NFTFlowFactory: SendGenericFlowFactory {
    func make(router: any SendRoutable) -> SendViewModel {
        let header = sourceToken.header
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
        sendModel.informationRelevanceService = CommonInformationRelevanceService(
            input: sendModel, provider: sendModel
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
            feeSelectorBuilder: fee.feeSelectorBuilder,
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
            sourceWalletData: .init(
                walletAddresses: sendingWalletDestinationStepDataInput.walletAddresses,
                suggestedWallets: sendingWalletDestinationStepDataInput.suggestedWallets,
                destinationTransactionHistoryProvider: CommonSendDestinationTransactionHistoryProvider(
                    transactionHistoryUpdater: sendingWalletDestinationStepDataInput.walletModelHistoryUpdater,
                    transactionHistoryMapper: TransactionHistoryMapper(
                        currencySymbol: tokenItem.currencySymbol,
                        walletAddresses: sendingWalletDestinationStepDataInput.walletAddresses,
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
    var feeDependencies: SendFeeStepBuilder.Dependencies {
        SendFeeStepBuilder.Dependencies(
            tokenFeeManagerProviding: sendModel,
            feeSelectorOutput: sendModel,
            analyticsLogger: analyticsLogger
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
            sendFeeProvider: sendModel,
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
