//
//  RavencoinTransactionRecordMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct RavencoinTransactionRecordMapper {
    private let blockchain: Blockchain

    init(blockchain: Blockchain) {
        assert(blockchain.isUTXO, "RavencoinTransactionRecordMapper support only UTXO blockchains")
        self.blockchain = blockchain
    }
}

// MARK: - TransactionRecordMapper

extension RavencoinTransactionRecordMapper: TransactionRecordMapper {
    func mapToTransactionRecord(transaction: RavencoinDTO.TransactionInfo.Response, address: String) throws -> TransactionRecord {
        let isOutgoing = transaction.vin.contains(where: { $0.addr == address })
        let sources: [TransactionRecord.Source] = transaction.vin.map {
            .init(address: $0.addr, amount: $0.value)
        }
        let destinations: [TransactionRecord.Destination] = transaction.vout.compactMap { output in
            Decimal(stringValue: output.value).map {
                .init(address: .user(output.scriptPubKey.addresses.first ?? .unknown), amount: $0)
            }
        }

        let fee: Decimal = transaction.fees
        let date = transaction.time.map { Date(timeIntervalSince1970: TimeInterval($0)) } ?? Date()
        let isConfirmed: Bool = (transaction.blockheight) > 0

        return TransactionRecord(
            hash: transaction.txid,
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
