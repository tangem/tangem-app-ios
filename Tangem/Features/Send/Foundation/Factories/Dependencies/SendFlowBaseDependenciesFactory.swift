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
}

// MARK: - Shared dependencies

extension SendFlowBaseDependenciesFactory {
    // MARK: - Management Model

    func makeTransferModel(
        analyticsLogger: any SendManagementModelAnalyticsLogger,
        predefinedValues: TransferModel.PredefinedValues
    ) -> TransferModel {
        TransferModel(
            userWalletId: userWalletInfo.id,
            userToken: transferableToken,
            transactionSigner: userWalletInfo.signerFactory.makeSigner(),
            feeIncludedCalculator: CommonFeeIncludedCalculator(validator: transferableToken.transactionValidator),
            analyticsLogger: analyticsLogger,
            sendAlertBuilder: makeSendAlertBuilder(),
            predefinedValues: predefinedValues
        )
    }

    func makePredefinedTransferValues(parameters: PredefinedSendParameters?) -> TransferModel.PredefinedValues {
        guard let parameters else {
            return .init()
        }

        let destination = SendDestination(value: .plain(parameters.destination), source: .qrCode)

        let amount = parameters.amount.map { amount in
            let fiatValue = tokenItem.currencyId.flatMap { currencyId in
                BalanceConverter().convertToFiat(amount, currencyId: currencyId)
            }

            return SendAmount(type: .typical(crypto: amount, fiat: fiatValue))
        }

        let additionalField: SendDestinationAdditionalField = {
            guard let type = SendDestinationAdditionalFieldType.type(for: tokenItem.blockchain) else {
                return .notSupported
            }

            guard let tag = parameters.tag?.nilIfEmpty else {
                return .empty(type: type)
            }

            do {
                let params = try makeTransactionParametersBuilder().transactionParameters(value: tag)
                return .filled(type: type, value: tag, params: params)
            } catch {
                assertionFailure("Failed to build transaction parameters for predefined tag: \(error)")
                return .empty(type: type)
            }
        }()

        return TransferModel.PredefinedValues(
            destination: destination,
            tag: additionalField,
            amount: amount
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
