//
//  BlockchairTransactionRecordMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct BlockchairTransactionRecordMapper {
    private let blockchain: Blockchain

    init(blockchain: Blockchain) {
        assert(blockchain.isUTXO, "BlockBookTransactionTransactionRecordMapper support only UTXO blockchains")
        self.blockchain = blockchain
    }
}

// MARK: - TransactionRecordMapper

extension BlockchairTransactionRecordMapper: TransactionRecordMapper {
    func mapToTransactionRecord(transaction: BlockchairDTO.TransactionInfo.Response.Transaction, address: String) throws -> TransactionRecord {
        let isOutgoing = transaction.inputs.contains(where: { $0.recipient == address })
        let sources: [TransactionRecord.Source] = transaction.inputs.map {
            .init(address: $0.recipient, amount: Decimal($0.value) / blockchain.decimalValue)
        }
        let destinations: [TransactionRecord.Destination] = transaction.outputs.map {
            .init(address: .user($0.recipient), amount: Decimal($0.value) / blockchain.decimalValue)
        }

        let fee = Decimal(transaction.transaction.fee) / blockchain.decimalValue
        let date = transaction.transaction.time

        return TransactionRecord(
            hash: transaction.transaction.hash,
            index: 0,
            source: .from(sources),
            destination: .from(destinations),
            fee: .init(.init(with: blockchain, type: .coin, value: fee)),
            status: transaction.transaction.blockId > 0 ? .confirmed : .unconfirmed,
            isOutgoing: isOutgoing,
            type: .transfer,
            date: date,
            tokenTransfers: nil
        )
    }
}
