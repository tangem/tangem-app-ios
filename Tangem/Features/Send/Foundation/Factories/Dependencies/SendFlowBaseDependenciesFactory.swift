//
//  SendFlowBaseDependenciesFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemUI

protocol SendFlowBaseDependenciesFactory: SendGenericFlowBaseDependenciesFactory {
    var sourceToken: SendSourceToken { get }
}

extension SendFlowBaseDependenciesFactory {
    var userWalletInfo: UserWalletInfo { sourceToken.userWalletInfo }
    var tokenItem: TokenItem { sourceToken.tokenItem }
    var feeTokenItem: TokenItem { sourceToken.feeTokenItem }
    var tokenIconInfo: TokenIconInfo { sourceToken.tokenIconInfo }
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
            userToken: sourceToken,
            transactionSigner: userWalletInfo.signer,
            feeIncludedCalculator: CommonFeeIncludedCalculator(validator: sourceToken.transactionValidator),
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

    func makeBlockchainSDKNotificationMapper() -> BlockchainSDKNotificationMapper {
        BlockchainSDKNotificationMapper(tokenItem: tokenItem)
    }

    // MARK: - TransactionSummaryDescriptionBuilders

    func makeSendTransactionSummaryDescriptionBuilder() -> SendTransactionSummaryDescriptionBuilder {
        if case .nonFungible = tokenItem.token?.metadata.kind {
            return NFTSendTransactionSummaryDescriptionBuilder()
        }

        switch tokenItem.blockchain {
        case .koinos:
            return KoinosSendTransactionSummaryDescriptionBuilder(tokenItem: tokenItem)
        case .tron where tokenItem.isToken:
            return TronSendTransactionSummaryDescriptionBuilder(tokenItem: tokenItem)
        default:
            return CommonSendTransactionSummaryDescriptionBuilder(tokenItem: tokenItem)
        }
    }

    // MARK: - Notifications

    func makeSendNotificationManager() -> SendNotificationManager {
        CommonSendNotificationManager(
            userWalletId: userWalletInfo.id,
            tokenItem: tokenItem,
            withdrawalNotificationProvider: sourceToken.withdrawalNotificationProvider
        )
    }
}
