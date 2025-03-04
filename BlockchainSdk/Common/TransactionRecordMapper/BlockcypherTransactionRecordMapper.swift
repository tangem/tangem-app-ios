//
//  BlockcypherTransactionRecordMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct BlockcypherTransactionRecordMapper {
    private let blockchain: Blockchain

    init(blockchain: Blockchain) {
        assert(blockchain.isUTXO, "BlockBookTransactionTransactionRecordMapper support only UTXO blockchains")
        self.blockchain = blockchain
    }
}

// MARK: - TransactionRecordMapper

extension BlockcypherTransactionRecordMapper: TransactionRecordMapper {
    func mapToTransactionRecord(transaction: BlockcypherDTO.TransactionInfo.Response, address: String) throws -> TransactionRecord {
        let isOutgoing = transaction.inputs.contains(where: { $0.addresses.contains(address) })
        let sources: [TransactionRecord.Source] = transaction.inputs.map {
            .init(address: $0.addresses.first ?? .unknown, amount: Decimal($0.outputValue) / blockchain.decimalValue)
        }
        let destinations: [TransactionRecord.Destination] = transaction.outputs.map {
            .init(address: .user($0.addresses.first ?? .unknown), amount: $0.value / blockchain.decimalValue)
        }

        let fee: Decimal = transaction.fees / blockchain.decimalValue
        let date = transaction.confirmed ?? Date()

        return TransactionRecord(
            hash: transaction.hash,
            index: 0,
            source: .from(sources),
            destination: .from(destinations),
            fee: .init(.init(with: blockchain, type: .coin, value: fee)),
            status: transaction.blockHeight > 0 ? .confirmed : .unconfirmed,
            isOutgoing: isOutgoing,
            type: .transfer,
            date: date,
            tokenTransfers: nil
        )
    }
}
