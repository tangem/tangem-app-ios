//
//  SendFlowBaseDependenciesFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemUI

protocol SendFlowBaseDependenciesFactory: SendGenericFlowBaseDependenciesFactory {
    var tokenFeeLoader: any TokenFeeLoader { get }
    var expressDependenciesFactory: ExpressDependenciesFactory { get }
}

// MARK: - Shared dependencies

extension SendFlowBaseDependenciesFactory {
    // MARK: - Management Model

    func makeSendWithSwapModel(
        swapManager: SwapManager,
        analyticsLogger: any SendAnalyticsLogger,
        predefinedValues: SendModel.PredefinedValues
    ) -> SendModel {
        SendModel(
            userToken: makeSourceToken(),
            transactionSigner: userWalletInfo.signer,
            feeIncludedCalculator: CommonFeeIncludedCalculator(validator: walletModelDependenciesProvider.transactionValidator),
            analyticsLogger: analyticsLogger,
            sendReceiveTokenBuilder: makeSendReceiveTokenBuilder(),
            sendAlertBuilder: makeSendAlertBuilder(),
            swapManager: swapManager,
            predefinedValues: predefinedValues
        )
    }

    func makeSwapManager() -> any SwapManager {
        CommonSwapManager(
            userWalletConfig: userWalletInfo.config,
            interactor: expressDependenciesFactory.expressInteractor
        )
    }

    func makeSendAlertBuilder() -> SendAlertBuilder {
        CommonSendAlertBuilder()
    }

    func makeTransactionParametersBuilder() -> TransactionParamsBuilder {
        TransactionParamsBuilder(blockchain: tokenItem.blockchain)
    }

    // MARK: - Fee

    func makeSendWithSwapFeeProvider(
        receiveTokenInput: SendReceiveTokenInput,
        sendFeeProvider: SendFeeProvider,
        swapFeeProvider: SendFeeProvider
    ) -> SendFeeProvider {
        SendWithSwapFeeProvider(
            receiveTokenInput: receiveTokenInput,
            sendFeeProvider: sendFeeProvider,
            swapFeeProvider: swapFeeProvider
        )
    }

    func makeSendFeeProvider(input: any SendFeeProviderInput, customFeeProvider: (any CustomFeeProvider)?) -> SendFeeProvider {
        let feeProvider = CommonSendFeeProvider(
            feeLoader: tokenFeeLoader,
            customFeeProvider: customFeeProvider,
            initialTokenItem: feeTokenItem
        )

        feeProvider.setup(input: input)
        return feeProvider
    }

    func makeSwapFeeProvider(swapManager: SwapManager) -> SendFeeProvider {
        SwapFeeProvider(swapManager: swapManager)
    }

    func makeCustomFeeService(input: SendFeeProviderInput) -> CustomFeeProvider? {
        let factory = CustomFeeServiceFactory(
            tokenItem: tokenItem,
            feeTokenItem: feeTokenItem,
            bitcoinTransactionFeeCalculator: walletModelDependenciesProvider.bitcoinTransactionFeeCalculator
        )

        let service = factory.makeService()
        (service as? SendCustomFeeService)?.setup(input: input)

        return service
    }

    // MARK: - Notifications

    func makeSendWithSwapNotificationManager(receiveTokenInput: SendReceiveTokenInput) -> SendNotificationManager {
        SendWithSwapNotificationManager(
            receiveTokenInput: receiveTokenInput,
            sendNotificationManager: CommonSendNotificationManager(
                userWalletId: userWalletInfo.id,
                tokenItem: tokenItem,
                feeTokenItem: feeTokenItem,
                withdrawalNotificationProvider: walletModelDependenciesProvider.withdrawalNotificationProvider
            ),
            expressNotificationManager: ExpressNotificationManager(
                userWalletId: userWalletInfo.id,
                expressInteractor: expressDependenciesFactory.expressInteractor
            )
        )
    }

    // MARK: - Receive token

    func makeSendReceiveTokenBuilder() -> SendReceiveTokenBuilder {
        SendReceiveTokenBuilder(tokenIconInfoBuilder: TokenIconInfoBuilder(), fiatItem: makeFiatItem())
    }

    // MARK: - Services

    func makeSendQRCodeService() -> SendQRCodeService {
        CommonSendQRCodeService(
            parser: QRCodeParser(
                amountType: tokenItem.amountType,
                blockchain: tokenItem.blockchain,
                decimalCount: tokenItem.decimalCount
            )
        )
    }

    // MARK: - Analytics

    static func makeSendAnalyticsLogger(
        walletModel: any WalletModel,
        sendType: CommonSendAnalyticsLogger.SendType
    ) -> SendAnalyticsLogger {
        CommonSendAnalyticsLogger(
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            feeAnalyticsParameterBuilder: FeeAnalyticsParameterBuilder(isFixedFee: !walletModel.shouldShowFeeSelector),
            sendType: sendType
        )
    }
}
