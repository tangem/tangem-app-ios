//
//  CardanoStakeKitTransactionHelper.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore
import PotentCBOR

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

    func cardanoTransaction(from unsignedData: String) throws -> CardanoTransaction {
        let data = Data(hex: unsignedData)

        let cbor = try CBORSerialization.cbor(from: data)

        guard let body = CardanoTransactionBody(cbor: cbor) else {
            throw BlockchainSdkError.failedToBuildTx
        }

        return CardanoTransaction(body: body, witnessSet: nil, isValid: true, auxiliaryData: nil)
    }
}
