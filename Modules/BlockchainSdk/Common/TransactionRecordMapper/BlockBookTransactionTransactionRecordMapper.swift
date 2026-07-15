//
//  BlockBookTransactionTransactionRecordMapper.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct BlockBookTransactionTransactionRecordMapper {
    private let blockchain: Blockchain

    init(blockchain: Blockchain) {
        assert(blockchain.isUTXO, "BlockBookTransactionTransactionRecordMapper support only UTXO blockchains")
        self.blockchain = blockchain
    }
}

// MARK: - TransactionRecordMapper

extension BlockBookTransactionTransactionRecordMapper: TransactionRecordMapper {
    func mapToTransactionRecord(transaction: BlockBookAddressResponse.Transaction, address: String) throws -> TransactionRecord {
        try UTXOTransactionHistoryMapper(blockchain: blockchain)
            .mapToTransactionRecord(transaction: transaction, walletAddress: [address])
    }
}
