//
//  WCBtcTransactionBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol WCBtcTransactionBuilder {
    func buildTx(
        from transaction: WalletConnectBtcTransaction,
        for walletModel: any WalletModel
    ) async throws -> Transaction

    func buildPsbtHashes(
        from psbtBase64: String,
        signInputs: [WalletConnectPsbtSignInput]
    ) throws -> [Data]
}

struct CommonWCBtcTransactionBuilder {}

extension CommonWCBtcTransactionBuilder: WCBtcTransactionBuilder {
    func buildTx(
        from wcTransaction: WalletConnectBtcTransaction,
        for walletModel: any WalletModel
    ) async throws -> Transaction {
        let blockchain = walletModel.tokenItem.blockchain

        guard let amountDecimal = Decimal(string: wcTransaction.amount) else {
            let error = WalletConnectTransactionRequestProcessingError.invalidPayload("Invalid BTC amount: \(wcTransaction.amount)")
            WCLogger.error(error: error)
            throw error
        }

        let btcDecimals = amountDecimal / blockchain.decimalValue
        let amount = Amount(with: blockchain, type: .coin, value: btcDecimals)

        async let walletUpdate: () = walletModel.update(silent: false, features: .balances)
        async let feesResult = walletModel.tokenFeeLoader.getFee(
            amount: amount.value,
            destination: wcTransaction.recipientAddress
        )

        let fees = try await feesResult
        let _ = await walletUpdate

        let selectedFee: Fee = selectDefaultFee(from: fees) ?? Fee(Amount(with: blockchain, value: 0))

        let transaction = try await walletModel.transactionCreator.createTransaction(
            amount: amount,
            fee: selectedFee,
            sourceAddress: wcTransaction.account,
            destinationAddress: wcTransaction.recipientAddress,
            changeAddress: wcTransaction.changeAddress,
            contractAddress: nil,
            params: nil
        )

        return transaction
    }

    func buildPsbtHashes(
        from psbtBase64: String,
        signInputs: [WalletConnectPsbtSignInput]
    ) throws -> [Data] {
        let hashesToSign = try BlockchainSdk.BitcoinPsbtSigningBuilder.hashesToSign(
            psbtBase64: psbtBase64,
            signInputs: signInputs.map { BlockchainSdk.BitcoinPsbtSigningBuilder.SignInput(index: $0.index) }
        )
        return hashesToSign
    }

    private func selectDefaultFee(from fees: [Fee]) -> Fee? {
        // Prefer 'market' (middle) if available; else first available
        if fees.count >= 3 {
            return fees[1]
        } else {
            return fees.first
        }
    }
}
