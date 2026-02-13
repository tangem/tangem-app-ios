//
//  SendFlowBaseDependenciesFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemUI

protocol SendFlowBaseDependenciesFactory: SendGenericFlowBaseDependenciesFactory {
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
            userWalletId: userWalletInfo.id,
            userToken: sourceToken,
            transactionSigner: userWalletInfo.signer,
            feeIncludedCalculator: CommonFeeIncludedCalculator(validator: sourceToken.transactionValidator),
            analyticsLogger: analyticsLogger,
            sendReceiveTokenBuilder: makeSendReceiveTokenBuilder(),
            sendAlertBuilder: makeSendAlertBuilder(),
            swapManager: swapManager,
            predefinedValues: predefinedValues
        )
    }

    func makeSwapManager() -> SwapManager {
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

    // MARK: - Notifications

    func makeSendWithSwapNotificationManager(receiveTokenInput: SendReceiveTokenInput) -> SendNotificationManager {
        SendWithSwapNotificationManager(
            receiveTokenInput: receiveTokenInput,
            sendNotificationManager: CommonSendNotificationManager(
                userWalletId: userWalletInfo.id,
                tokenItem: tokenItem,
                withdrawalNotificationProvider: sourceToken.withdrawalNotificationProvider
            ),
            expressNotificationManager: ExpressNotificationManager(
                userWalletId: userWalletInfo.id,
                expressInteractor: expressDependenciesFactory.expressInteractor
            )
        )
    }

    // MARK: - Receive token

    func makeSendReceiveTokenBuilder() -> SendReceiveTokenBuilder {
        SendReceiveTokenBuilder(tokenIconInfoBuilder: TokenIconInfoBuilder(), fiatItem: sourceToken.fiatItem)
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

    func makeSendAnalyticsLogger(sendType: CommonSendAnalyticsLogger.SendType) -> SendAnalyticsLogger {
        CommonSendAnalyticsLogger(
            tokenItem: tokenItem,
            feeTokenItem: feeTokenItem,
            feeAnalyticsParameterBuilder: FeeAnalyticsParameterBuilder(isFixedFee: !sourceToken.tokenFeeProvidersManager.supportFeeSelection),
            sendType: sendType
        )
    }
}
