//
//  SendWithSwapFlowBaseDependenciesFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol SendWithSwapFlowBaseDependenciesFactory: SendFlowBaseDependenciesFactory, SwapFlowBaseDependenciesFactory {}

// MARK: - Shared dependencies

extension SendWithSwapFlowBaseDependenciesFactory {
    func makeSendModel(
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

    func makeSwapManager(expressInteractor: ExpressInteractor) -> SwapManager {
        CommonSwapManager(
            userWalletConfig: userWalletInfo.config,
            interactor: expressInteractor
        )
    }

    func makeSendWithSwapModel(
        transferModel: TransferModel,
        swapModel: SwapModel,
        analyticsLogger: any SendAnalyticsLogger,
        predefinedValues: TransferModel.PredefinedValues,
        autoupdatingTimer: AutoupdatingTimer,
    ) -> SendWithSwapModel {
        return SendWithSwapModel(
            transferModel: transferModel,
            swapModel: swapModel,
            initialSourceToken: sourceToken,
            receiveTokenBuilder: makeSendReceiveTokenBuilder(),
            sendAlertBuilder: makeSendAlertBuilder(),
            analyticsLogger: analyticsLogger
        )
    }

    // MARK: - Receive token

    func makeSendReceiveTokenBuilder() -> SendReceiveTokenBuilder {
        SendReceiveTokenBuilder(tokenIconInfoBuilder: TokenIconInfoBuilder(), fiatItem: sourceToken.fiatItem)
    }

    // MARK: - Notifications

    func makeSendWithSwapNotificationManager(receiveTokenInput: SendReceiveTokenInput, expressInteractor: ExpressInteractor) -> SendNotificationManager {
        SendWithSwapNotificationManager(
            receiveTokenInput: receiveTokenInput,
            sendNotificationManager: makeSendNotificationManager(),
            expressNotificationManager: ExpressNotificationManager(
                userWalletId: userWalletInfo.id,
                expressInteractor: expressInteractor
            )
        )
    }
}
