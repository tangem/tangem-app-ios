//
//  TransferFlowFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct TangemUI.TokenIconInfo

class TransferNFTFlowFactory: SendFlowBaseDependenciesFactory {
    let transferableToken: SendTransferableToken
    let nftAssetStepBuilder: NFTAssetStepBuilder

    lazy var analyticsLogger: SendAnalyticsLogger = makeSendAnalyticsLogger(sendType: .send)
    lazy var sendModel = makeTransferModel(
        analyticsLogger: analyticsLogger,
        predefinedValues: .init(
            amount: .init(type: .typical(crypto: NFTSendUtil.amountToSend, fiat: .none))
        )
    )

    lazy var notificationManager = makeSendNotificationManager()

    init(
        transferableToken: SendTransferableToken,
        nftAssetStepBuilder: NFTAssetStepBuilder
    ) {
        self.transferableToken = transferableToken
        self.nftAssetStepBuilder = nftAssetStepBuilder
    }
}

// MARK: - SendGenericFlowFactory

extension TransferNFTFlowFactory: SendGenericFlowFactory {
    func make(router: any SendRoutable) -> SendViewModel {
        let header = transferableToken.header.asSendTokenHeader(actionType: .send)
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

        let stepsManager = CommonNFTSendStepsManager(
            destinationStep: destination.step,
            feeSelectorBuilder: fee.feeSelectorBuilder,
            summaryStep: summary,
            finishStep: finish,
            summaryTitleProvider: CommonSendSummaryTitleProvider(tokenItem: transferableToken.tokenItem),
            confirmTransactionPolicy: CommonConfirmTransactionPolicy(userWalletInfo: userWalletInfo),
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

extension TransferNFTFlowFactory: SendBaseBuildable {
    var baseIO: SendViewModelBuilder.IO {
        SendViewModelBuilder.IO(input: sendModel, output: sendModel)
    }

    var baseDependencies: SendViewModelBuilder.Dependencies {
        SendViewModelBuilder.Dependencies(
            alertBuilder: makeSendAlertBuilder(),
            mailDataBuilder: CommonSendMailDataBuilder(
                baseDataInput: sendModel,
                sourceTokenInput: sendModel
            ),
            approveViewModelInputDataBuilder: EmptyApproveViewModelInputDataBuilder(),
            feeCurrencyProviderDataBuilder: CommonSendFeeCurrencyProviderDataBuilder(
                sourceTokenInput: sendModel
            ),
            analyticsLogger: analyticsLogger,
            blockchainSDKNotificationMapper: BlockchainSDKNotificationMapper(tokenItem: tokenItem),
            tangemIconProvider: CommonTangemIconProvider(config: userWalletInfo.config)
        )
    }
}

// MARK: - SendDestinationStepBuildable

extension TransferNFTFlowFactory: SendDestinationStepBuildable {
    var destinationIO: SendDestinationStepBuilder.IO {
        SendDestinationStepBuilder.IO(
            input: sendModel,
            output: sendModel,
            receiveTokenInput: .none,
            destinationAccountOutput: sendModel
        )
    }

    var destinationTypes: SendDestinationStepBuilder.Types {
        .init(initialSourceToken: transferableToken)
    }

    var destinationDependencies: SendDestinationStepBuilder.Dependencies {
        SendDestinationStepBuilder.Dependencies(
            sendQRCodeService: makeSendQRCodeService(),
            analyticsLogger: analyticsLogger,
            destinationInteractorDependenciesProvider: SendDestinationInteractorDependenciesProvider(
                sourceToken: transferableToken,
                receivedToken: .none,
                analyticsLogger: analyticsLogger,
                receiveTokenWalletDataProvider: SendReceiveTokenWalletDataProvider()
            )
        )
    }
}

// MARK: - SendFeeStepBuildable

extension TransferNFTFlowFactory: SendFeeStepBuildable {
    var feeDependencies: SendFeeStepBuilder.Dependencies {
        SendFeeStepBuilder.Dependencies(
            tokenFeeManagerProviding: sendModel,
            feeSelectorOutput: sendModel,
            analyticsLogger: analyticsLogger
        )
    }
}

// MARK: - SendSummaryStepBuildable

extension TransferNFTFlowFactory: SendSummaryStepBuildable {
    var summaryIO: SendSummaryStepBuilder.IO {
        SendSummaryStepBuilder.IO(input: sendModel, output: sendModel)
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
            sendWithSwapDescriptionBuilder: makeSendWithSwapTransactionSummaryDescriptionBuilder(),
            stakingDescriptionBuilder: makeStakingTransactionSummaryDescriptionBuilder(),
        )
    }
}

// MARK: - SendFinishStepBuildable

extension TransferNFTFlowFactory: SendFinishStepBuildable {
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
