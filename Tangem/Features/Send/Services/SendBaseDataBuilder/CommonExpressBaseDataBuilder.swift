//
//  CommonExpressBaseDataBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import BlockchainSdk
import TangemStaking
import TangemFoundation

struct CommonExpressBaseDataBuilder: ExpressBaseDataBuilder {
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

    func makeMailData(transactionResult: ExpressTransactionResult, error: SendTxError) -> (dataCollector: any EmailDataCollector, recipient: String) {
        switch transactionResult {
        case .default(let transaction):
            return makeMailData(transaction: transaction, error: error)
        case .compiled(let unsignedData):
            return makeCompiledData(transactionData: unsignedData, error: error)
        }
    }

    // MARK: - Private Implementation

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

    func makeCompiledData(transactionData: Data, error: SendTxError) -> (dataCollector: EmailDataCollector, recipient: String) {
        let emailDataCollector = CompiledExpressDataCollector(
            userWalletEmailData: emailDataProvider.emailData,
            walletModel: walletModel,
            transactionHex: transactionData.hexString,
            lastError: error
        )

        let recipient = emailDataProvider.emailConfig?.recipient ?? EmailConfig.default.recipient

        return (dataCollector: emailDataCollector, recipient: recipient)
    }
}
