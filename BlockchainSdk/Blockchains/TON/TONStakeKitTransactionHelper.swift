//
//  TONStakeKitTransactionHelper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TonSwift

class TONStakeKitTransactionHelper {
    private let transactionBuilder: TONTransactionBuilder

    init(transactionBuilder: TONTransactionBuilder) {
        self.transactionBuilder = transactionBuilder
    }

    func prepareForSign(_ stakingTransaction: StakeKitTransaction, expireAt: UInt32) throws -> TONPreSignData {
        print(stakingTransaction)
        guard let data = stakingTransaction.unsignedData.data(using: .utf8) else {
            throw WalletError.failedToBuildTx
        }

        let decodedTransaction = try JSONDecoder().decode(UnsignedTransaction.self, from: data)
        let decodedMessage: [UInt8] = try decodedTransaction.message.base64Decoded()
        let cells = try Cell.fromBoc(src: Data(decodedMessage))

        guard let cell = cells.first else {
            throw WalletError.failedToBuildTx
        }

        let slice = try cell.beginParse()
        let message: MessageRelaxed = try slice.loadType()

        guard case .internalInfo(let info) = message.info else {
            throw WalletError.failedToBuildTx
        }

        return try transactionBuilder.buildCompiledForSign(
            buildInput: info,
            sequenceNumber: Int(decodedTransaction.seqno) ?? 0,
            expireAt: expireAt
        )
    }

    func prepareForSend(
        stakingTransaction: StakeKitTransaction,
        preSignData: TONPreSignData,
        signatureInfo: SignatureInfo
    ) throws -> String {
        try transactionBuilder.buildForSend(
            serializedInputData: preSignData.serializedTransactionInput,
            signature: signatureInfo.signature
        )
    }
}

struct UnsignedTransaction: Decodable {
    let seqno: String
    let message: String
}
