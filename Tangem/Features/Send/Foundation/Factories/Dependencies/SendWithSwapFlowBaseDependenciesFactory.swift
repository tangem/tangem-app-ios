//
//  SendWithSwapFlowBaseDependenciesFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol SendWithSwapFlowBaseDependenciesFactory: SendFlowBaseDependenciesFactory {
    var expressInteractorFactory: ExpressInteractorFactory { get }
}

// MARK: - Shared dependencies

extension SendWithSwapFlowBaseDependenciesFactory {
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
            interactor: expressInteractorFactory.expressInteractor
        )
    }

    // MARK: - Receive token

    func makeSendReceiveTokenBuilder() -> SendReceiveTokenBuilder {
        SendReceiveTokenBuilder(tokenIconInfoBuilder: TokenIconInfoBuilder(), fiatItem: sourceToken.fiatItem)
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
                expressInteractor: expressInteractorFactory.expressInteractor
            )
        )
    }
}
