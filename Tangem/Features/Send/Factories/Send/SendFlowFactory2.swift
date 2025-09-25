//
//  SendFlowFactory2.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemUI
import BlockchainSdk

class SendFlowFactory2: SendFlowBaseFactory {
    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem

    convenience init(
        walletModel: any WalletModel,
        userWalletInfo: SendWalletInfo,
        expressInput: CommonExpressDependenciesFactory.Input
    ) {
        self.init(
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            dependencies: SendFlowDependenciesFactory(
                tokenItem: walletModel.tokenItem,
                feeTokenItem: walletModel.feeTokenItem,
                tokenIconInfo: TokenIconInfoBuilder().build(
                    from: walletModel.tokenItem,
                    isCustom: walletModel.isCustom
                ),
                userWalletInfo: userWalletInfo,
                walletAddresses: walletModel.addresses.map(\.value),
                suggestedWallets: SendSuggestedWalletsFactory().makeSuggestedWallets(
                    walletModel: walletModel
                ),
                shouldShowFeeSelector: walletModel.shouldShowFeeSelector,
                sendBaseDataBuilderFactory: SendBaseDataBuilderFactory(
                    walletModel: walletModel,
                    emailDataProvider: userWalletInfo.emailDataProvider
                ),
                walletModelHistoryUpdater: walletModel,
                walletModelFeeProvider: walletModel,
                walletModelDependenciesProvider: walletModel,
                walletModelBalancesProvider: walletModel,
                transactionDispatcherFactory: TransactionDispatcherFactory(
                    walletModel: walletModel,
                    signer: userWalletInfo.signer
                ),
                expressDependenciesFactory: CommonExpressDependenciesFactory(
                    input: expressInput,
                    initialWallet: walletModel.asExpressInteractorWallet,
                    destinationWallet: .none,
                    // We support only `CEX` in `Send With Swap` flow
                    supportedProviderTypes: [.cex],
                    operationType: .swapAndSend
                )
            )
        )
    }

    init(tokenItem: TokenItem, feeTokenItem: TokenItem, dependencies: SendFlowDependenciesFactory) {
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem

        super.init(dependencies: dependencies)
    }

    func make(router: any SendRoutable) -> SendViewModel {
        let amount = makeSendAmountStep()
        let destination = makeSendDestinationStep(router: router)
        let fee = makeSendFeeStep()
        let providers = makeSwapProviders()

        let summary = makeSendNewSummaryStep(
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
        sendModel.externalAmountUpdater = amount.amountUpdater
        sendModel.externalDestinationUpdater = destination.externalUpdater
        sendModel.sendFeeProvider = sendFeeProvider
        sendModel.informationRelevanceService = dependencies.makeInformationRelevanceService(
            input: sendModel, output: sendModel, provider: sendFeeProvider
        )

        // Steps setup
        fee.compact.bind(input: sendModel)
        fee.finish.bind(input: sendModel)

        // Notifications setup
        notificationManager.setup(input: sendModel)
        notificationManager.setupManager(with: sendModel)

        // Logger setup
        analyticsLogger.setup(sendFeeInput: sendModel)
        analyticsLogger.setup(sendSourceTokenInput: sendModel)
        analyticsLogger.setup(sendReceiveTokenInput: sendModel)
        analyticsLogger.setup(sendSwapProvidersInput: sendModel)

        let stepsManager = CommonSendStepsManager(
            amountStep: amount.step,
            destinationStep: destination.step,
            summaryStep: summary,
            finishStep: finish,
            feeSelector: fee.feeSelector,
            providersSelector: providers,
            summaryTitleProvider: dependencies.makeSendWithSwapSummaryTitleProvider(receiveTokenInput: sendModel)
        )

        let dataBuilder = dependencies.makeSendBaseDataBuilder(
            input: sendModel,
            sendReceiveTokensListBuilder: dependencies.makeSendReceiveTokensListBuilder(
                sendSourceTokenInput: sendModel,
                receiveTokenOutput: sendModel,
                analyticsLogger: analyticsLogger,
            )
        )

        let viewModel = makeSendBase(stepsManager: stepsManager, router: router)

        amount.step.set(router: viewModel)
        destination.step.set(stepRouter: stepsManager)
        summary.set(router: stepsManager)

        sendModel.router = viewModel
        sendModel.alertPresenter = viewModel

        return viewModel
    }
}

// MARK: - SendBaseBuildable

extension SendFlowFactory2: SendBaseBuildable {
    var baseIO: SendViewModelBuilder.IO {
        SendViewModelBuilder.IO(input: sendModel, output: sendModel)
    }

    var baseTypes: SendViewModelBuilder.Types {
        SendViewModelBuilder.Types(tokenItem: tokenItem)
    }

    var baseDependencies: SendViewModelBuilder.Dependencies {
        SendViewModelBuilder.Dependencies(
            alertBuilder: dependencies.makeSendAlertBuilder(),
            dataBuilder: dependencies.makeSendBaseDataBuilder(
                input: sendModel,
                sendReceiveTokensListBuilder: dependencies.makeSendReceiveTokensListBuilder(
                    sendSourceTokenInput: sendModel,
                    receiveTokenOutput: sendModel,
                    analyticsLogger: analyticsLogger,
                )
            ),
            analyticsLogger: analyticsLogger,
            blockchainSDKNotificationMapper: dependencies.makeBlockchainSDKNotificationMapper()
        )
    }
}

// MARK: - SendNewAmountStepBuildable

extension SendFlowFactory2: SendNewAmountStepBuildable {
    var newAmountIO: SendNewAmountStepBuilder2.IO {
        SendNewAmountStepBuilder2.IO(
            sourceIO: (input: sendModel, output: sendModel),
            sourceAmountIO: (input: sendModel, output: sendModel),
            receiveIO: (input: sendModel, output: sendModel),
            receiveAmountIO: (input: sendModel, output: sendModel),
            swapProvidersInput: sendModel,
        )
    }

    var newAmountDependencies: SendNewAmountStepBuilder2.Dependencies {
        SendNewAmountStepBuilder2.Dependencies(
            sendAmountValidator: dependencies.makeSendSourceTokenAmountValidator(input: sendModel),
            amountModifier: .none,
            notificationService: notificationManager as? SendAmountNotificationService,
            analyticsLogger: analyticsLogger
        )
    }
}

// MARK: - SendDestinationStepBuildable

extension SendFlowFactory2: SendDestinationStepBuildable {
    var destinationIO: SendDestinationStepBuilder2.IO {
        SendDestinationStepBuilder2.IO(input: sendModel, output: sendModel, receiveTokenInput: sendModel)
    }

    var destinationDependencies: SendDestinationStepBuilder2.Dependencies {
        SendDestinationStepBuilder2.Dependencies(
            sendQRCodeService: sendQRCodeService,
            analyticsLogger: analyticsLogger,
            destinationInteractorDependenciesProvider: dependencies.makeSendDestinationInteractorDependenciesProvider(
                analyticsLogger: analyticsLogger
            ),
        )
    }
}

// MARK: - SendFeeStepBuildable

extension SendFlowFactory2: SendFeeStepBuildable {
    var feeIO: SendNewFeeStepBuilder2.IO {
        SendNewFeeStepBuilder2.IO(input: sendModel, output: sendModel)
    }

    var feeTypes: SendNewFeeStepBuilder2.Types {
        SendNewFeeStepBuilder2.Types(
            feeTokenItem: feeTokenItem,
            isFeeApproximate: dependencies.isFeeApproximate()
        )
    }

    var feeDependencies: SendNewFeeStepBuilder2.Dependencies {
        SendNewFeeStepBuilder2.Dependencies(
            feeProvider: sendFeeProvider,
            analyticsLogger: analyticsLogger,
            customFeeService: customFeeService
        )
    }
}

// MARK: - SendSwapProvidersBuildable

extension SendFlowFactory2: SendSwapProvidersBuildable {
    var swapProvidersIO: SendSwapProvidersBuilder2.IO {
        SendSwapProvidersBuilder2.IO(input: sendModel, output: sendModel, receiveTokenInput: sendModel)
    }

    var swapProvidersTypes: SendSwapProvidersBuilder2.Types {
        SendSwapProvidersBuilder2.Types(tokenItem: tokenItem)
    }

    var swapProvidersDependencies: SendSwapProvidersBuilder2.Dependencies {
        SendSwapProvidersBuilder2.Dependencies(
            analyticsLogger: analyticsLogger,
            expressProviderFormatter: .init(balanceFormatter: .init()),
            priceChangeFormatter: .init(percentFormatter: .init())
        )
    }
}

// MARK: - SendNewSummaryStepBuildable

extension SendFlowFactory2: SendNewSummaryStepBuildable {
    var newSummaryIO: SendNewSummaryStepBuilder2.IO {
        SendNewSummaryStepBuilder2.IO(input: sendModel, output: sendModel, receiveTokenAmountInput: sendModel)
    }

    var newSummaryDependencies: SendNewSummaryStepBuilder2.Dependencies {
        SendNewSummaryStepBuilder2.Dependencies(
            sendFeeProvider: sendFeeProvider,
            notificationManager: notificationManager,
            analyticsLogger: analyticsLogger,
            sendDescriptionBuilder: dependencies.makeSendTransactionSummaryDescriptionBuilder(),
            swapDescriptionBuilder: dependencies.makeSwapTransactionSummaryDescriptionBuilder()
        )
    }
}

// MARK: - SendNewFinishStepBuildable

extension SendFlowFactory2: SendNewFinishStepBuildable {
    var newFinishIO: SendNewFinishStepBuilder2.IO {
        SendNewFinishStepBuilder2.IO(input: sendModel)
    }

    var newFinishTypes: SendNewFinishStepBuilder2.Types {
        SendNewFinishStepBuilder2.Types(tokenItem: tokenItem)
    }

    var newFinishDependencies: SendNewFinishStepBuilder2.Dependencies {
        SendNewFinishStepBuilder2.Dependencies(
            analyticsLogger: analyticsLogger,
        )
    }
}
