//
//  CommonSendBaseDataBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import BlockchainSdk

protocol SendBaseDataBuilderInput {
    var bsdkAmount: BSDKAmount? { get }
    var bsdkFee: BSDKFee? { get }
    var isFeeIncluded: Bool { get }
}

struct CommonSendBaseDataBuilder: SendBaseDataBuilder {
    private let input: SendBaseDataBuilderInput
    private let walletModel: any WalletModel
    private let emailDataProvider: EmailDataProvider
    private let sendReceiveTokensListBuilder: SendReceiveTokensListBuilder?

    init(
        input: SendBaseDataBuilderInput,
        walletModel: any WalletModel,
        emailDataProvider: EmailDataProvider,
        sendReceiveTokensListBuilder: SendReceiveTokensListBuilder?
    ) {
        self.input = input
        self.walletModel = walletModel
        self.emailDataProvider = emailDataProvider
        self.sendReceiveTokensListBuilder = sendReceiveTokensListBuilder
    }

    func makeMailData(transaction: BSDKTransaction, error: SendTxError) -> (dataCollector: EmailDataCollector, recipient: String) {
        let emailDataCollector = SendScreenDataCollector(
            userWalletEmailData: emailDataProvider.emailData,
            walletModel: walletModel,
            fee: transaction.fee.amount,
            destination: transaction.destinationAddress,
            amount: transaction.amount,
            isFeeIncluded: input.isFeeIncluded,
            lastError: .init(error: error),
            stakingAction: nil,
            validator: nil
        )

        let recipient = emailDataProvider.emailConfig?.recipient ?? EmailConfig.default.recipient

        return (dataCollector: emailDataCollector, recipient: recipient)
    }

    func makeSendReceiveTokensList() throws -> SendReceiveTokensListBuilder {
        guard let sendReceiveTokensListBuilder else {
            throw SendBaseDataBuilderError.notFound("SendReceiveTokensListBuilder")
        }

        return sendReceiveTokensListBuilder
    }

    func makeFeeCurrencyData() -> (userWalletId: UserWalletId, feeTokenItem: TokenItem) {
        (userWalletId: walletModel.userWalletId, feeTokenItem: walletModel.feeTokenItem)
    }
}
