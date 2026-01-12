//
//  SendFlowBaseDependenciesFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemUI

protocol SendFlowBaseDependenciesFactory: SendGenericFlowBaseDependenciesFactory {
    var shouldShowFeeSelector: Bool { get }

    var tokenFeeManager: TokenFeeManager { get }
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

    func makeSwapManager() -> CommonSwapManager {
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

    func makeSendWithSwapFeeSelectorInteractor(
        receiveTokenInput: SendReceiveTokenInput,
        sendFeeSelectorInteractor: SendFlowTokenFeeProvider,
        swapFeeSelectorInteractor: SendFlowTokenFeeProvider
    ) -> SendWithSwapFeeSelectorInteractor {
        SendWithSwapFeeSelectorInteractor(
            receiveTokenInput: receiveTokenInput,
            sendFeeSelectorInteractor: sendFeeSelectorInteractor,
            swapFeeSelectorInteractor: swapFeeSelectorInteractor
        )
    }

    func makeSendFeeProvider(input: SendFeeInput, output: SendFeeOutput, dataInput: SendFeeProviderInput) -> SendFlowTokenFeeProvider {
        CommonSendFeeProvider(
            input: input,
            output: output,
            dataInput: dataInput,
            tokenFeeManager: tokenFeeManager
        )
    }

    func makeSwapFeeProvider(swapManager: SwapManager) -> SendFlowTokenFeeProvider {
        CommonSwapFeeProvider(
            expressInteractor: expressDependenciesFactory.expressInteractor
        )
    }

    func makeCustomFeeService(input: CustomFeeServiceInput) -> CustomFeeProvider? {
        return nil
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
