//
//  SendFlowBaseDependenciesFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemUI

protocol SendFlowBaseDependenciesFactory: SendGenericFlowBaseDependenciesFactory {
    var transferableToken: SendTransferableToken { get }
}

extension SendFlowBaseDependenciesFactory {
    var userWalletInfo: UserWalletInfo { transferableToken.userWalletInfo }
    var tokenItem: TokenItem { transferableToken.tokenItem }
    var feeTokenItem: TokenItem { transferableToken.feeTokenItem }
}

// MARK: - Shared dependencies

extension SendFlowBaseDependenciesFactory {
    // MARK: - Management Model

    func makeTransferModel(
        analyticsLogger: any SendAnalyticsLogger,
        predefinedValues: TransferModel.PredefinedValues
    ) -> TransferModel {
        TransferModel(
            userWalletId: userWalletInfo.id,
            userToken: transferableToken,
            transactionSigner: userWalletInfo.signer,
            feeIncludedCalculator: CommonFeeIncludedCalculator(validator: transferableToken.transactionValidator),
            analyticsLogger: analyticsLogger,
            sendAlertBuilder: makeSendAlertBuilder(),
            predefinedValues: predefinedValues
        )
    }

    // MARK: - Services

    func makeSendAlertBuilder() -> SendAlertBuilder {
        CommonSendAlertBuilder()
    }

    func makeTransactionParametersBuilder() -> TransactionParamsBuilder {
        TransactionParamsBuilder(blockchain: tokenItem.blockchain)
    }

    func makeSendQRCodeService() -> SendQRCodeService {
        CommonSendQRCodeService(
            parser: QRCodeParser(
                amountType: tokenItem.amountType,
                blockchain: tokenItem.blockchain,
                decimalCount: tokenItem.decimalCount
            )
        )
    }

    // MARK: - Notifications

    func makeSendNotificationManager() -> SendNotificationManager {
        CommonSendNotificationManager(
            userWalletId: userWalletInfo.id,
            tokenItem: tokenItem,
            withdrawalNotificationProvider: transferableToken.withdrawalNotificationProvider
        )
    }
}
