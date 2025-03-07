//
//  KaspaTransactionRecordMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct KaspaTransactionRecordMapper {
    private let blockchain: Blockchain

    init(blockchain: Blockchain) {
        assert(blockchain.isUTXO, "KaspaTransactionRecordMapper support only UTXO blockchains")
        self.blockchain = blockchain
    }
}

// MARK: - TransactionRecordMapper

extension KaspaTransactionRecordMapper: TransactionRecordMapper {
    func mapToTransactionRecord(transaction: KaspaDTO.TransactionInfo.Response, address: String) throws -> TransactionRecord {
        let isOutgoing = transaction.inputs.contains(where: { $0.previousOutpointAddress == address })
        let sources: [TransactionRecord.Source] = transaction.inputs.map {
            .init(address: $0.previousOutpointAddress, amount: Decimal($0.previousOutpointAmount) / blockchain.decimalValue)
        }
        let destinations: [TransactionRecord.Destination] = transaction.outputs.map {
            .init(address: .user($0.scriptPublicKeyAddress), amount: Decimal($0.amount) / blockchain.decimalValue)
        }
        let fee = (Decimal(stringValue: transaction.mass) ?? 0) / blockchain.decimalValue
        let date = transaction.blockTime.map { Date(timeIntervalSince1970: TimeInterval($0)) } ?? Date()
        let isConfirmed: Bool = (transaction.blockTime ?? 0) > 0

        return TransactionRecord(
            hash: transaction.transactionId,
            index: 0,
            source: .from(sources),
            destination: .from(destinations),
            fee: .init(.init(with: blockchain, type: .coin, value: fee)),
            status: isConfirmed ? .confirmed : .unconfirmed,
            isOutgoing: isOutgoing,
            type: .transfer,
            date: date,
            tokenTransfers: nil
        )
    }
}
