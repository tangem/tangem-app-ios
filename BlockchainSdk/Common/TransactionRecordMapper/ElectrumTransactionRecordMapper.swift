//
//  ElectrumTransactionRecordMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct ElectrumTransactionRecordMapper {
    typealias Transaction = (transaction: ElectrumDTO.Response.Transaction, inputs: [ElectrumDTO.Response.Vout])
    private let blockchain: Blockchain

    init(blockchain: Blockchain) {
        assert(blockchain.isUTXO, "BlockBookTransactionTransactionRecordMapper support only UTXO blockchains")
        self.blockchain = blockchain
    }
}

// MARK: - TransactionRecordMapper

extension ElectrumTransactionRecordMapper: TransactionRecordMapper {
    func mapToTransactionRecord(transaction: Transaction, address: String) throws -> TransactionRecord {
        let isOutgoing = transaction.inputs.contains(where: { $0.scriptPubKey.addresses.contains(address) })
        let sources: [TransactionRecord.Source] = transaction.inputs.map {
            .init(address: $0.scriptPubKey.addresses.first ?? .unknown, amount: $0.value)
        }
        let destinations: [TransactionRecord.Destination] = transaction.transaction.vout.map {
            .init(address: .user($0.scriptPubKey.addresses.first ?? .unknown), amount: $0.value)
        }

        let fee: Decimal = sources.reduce(0) { $0 + $1.amount } - destinations.reduce(0) { $0 + $1.amount }
        let date = transaction.transaction.time.map { Date(timeIntervalSince1970: TimeInterval($0)) } ?? Date()
        let isConfirmed: Bool = (transaction.transaction.confirmations ?? 0) > 0

        return TransactionRecord(
            hash: transaction.transaction.hash,
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
