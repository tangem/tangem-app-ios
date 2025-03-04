//
//  BitcoreTransactionRecordMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct BitcoreTransactionRecordMapper {
    typealias Transaction = (
        transaction: BitcoreDTO.TransactionInfo.Response,
        inputs: [BitcoreDTO.UTXO.Response],
        outputs: [BitcoreDTO.UTXO.Response]
    )

    private let blockchain: Blockchain

    init(blockchain: Blockchain) {
        assert(blockchain.isUTXO, "BitcoreTransactionRecordMapper support only UTXO blockchains")
        self.blockchain = blockchain
    }
}

// MARK: - TransactionRecordMapper

extension BitcoreTransactionRecordMapper: TransactionRecordMapper {
    func mapToTransactionRecord(transaction: Transaction, address: String) throws -> TransactionRecord {
        let isOutgoing = transaction.inputs.contains(where: { $0.address == address })
        let sources: [TransactionRecord.Source] = transaction.inputs.map {
            .init(address: $0.address, amount: Decimal($0.value) / blockchain.decimalValue)
        }
        let destinations: [TransactionRecord.Destination] = transaction.outputs.map {
            .init(address: .user($0.address), amount: Decimal($0.value) / blockchain.decimalValue)
        }
        let fee = Decimal(transaction.transaction.fee) / blockchain.decimalValue
        let date = transaction.transaction.blockTime ?? Date()
        let isConfirmed: Bool = (transaction.transaction.confirmations ?? 0) > 0

        return TransactionRecord(
            hash: transaction.transaction.txid,
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
