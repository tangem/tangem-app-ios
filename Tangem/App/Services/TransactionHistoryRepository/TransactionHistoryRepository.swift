//
//  TransactionHistoryRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Combine
import class TangemSwapping.ThreadSafeContainer

struct TransactionHistoryRepository {
    typealias StorageItem = [Blockchain: [TransactionRecord]]

    static var storage: ThreadSafeContainer<StorageItem> = [:]

    func records(blockchain: Blockchain) -> [TransactionRecord] {
        TransactionHistoryRepository.storage[blockchain] ?? []
    }

    func update(records: [TransactionRecord], for blockchain: Blockchain) {
        TransactionHistoryRepository.storage.mutate { value in
            value[blockchain, default: []] = records
        }
    }

    func add(records: [TransactionRecord], for blockchain: Blockchain) {
        TransactionHistoryRepository.storage.mutate { value in
            value[blockchain, default: []] += records
        }
    }
}
