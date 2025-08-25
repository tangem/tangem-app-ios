//
//  CardanoStakeKitTransactionHelper.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore
import SwiftCBOR

struct CardanoStakeKitTransactionHelper {
    private let transactionBuilder: CardanoTransactionBuilder

    init(transactionBuilder: CardanoTransactionBuilder) {
        self.transactionBuilder = transactionBuilder
    }

    func prepareForSign(_ transaction: StakeKitTransaction) throws -> Data {
        let transaction = try cardanoTransaction(from: transaction.unsignedData)
        return try transactionBuilder.buildCompiledForSign(transaction: transaction)
    }

    func prepareForSend(_ transaction: StakeKitTransaction, signatures: [SignatureInfo]) throws -> Data {
        let transaction = try cardanoTransaction(from: transaction.unsignedData)
        return try transactionBuilder.buildCompiledForSend(transaction: transaction, signatures: signatures)
    }

    private func cardanoTransaction(from unsignedData: String) throws -> CardanoTransaction {
        let data = Data(hex: unsignedData)
        guard let cbor = try CBOR.decode(data.bytes) else {
            throw BlockchainSdkError.failedToBuildTx
        }

        guard let body = CardanoTransactionBody(cbor: cbor) else {
            throw BlockchainSdkError.failedToBuildTx
        }

        return CardanoTransaction(body: body, witnessSet: nil, isValid: true, auxiliaryData: nil)
    }
}
