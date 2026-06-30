//
//  TransactionRecord+Merge.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public extension Array where Element == TransactionRecord {
    /// Appends new records, zipping `source`/`destination` of any record that already exists by `hash` + `index`.
    mutating func appendMerging(_ newRecords: [TransactionRecord]) {
        for record in newRecords {
            if let index = firstIndex(where: { $0.hash == record.hash && $0.index == record.index }) {
                let oldRecord = self[index]
                self[index] = TransactionRecord(
                    hash: record.hash,
                    index: record.index,
                    source: oldRecord.source + record.source,
                    destination: oldRecord.destination + record.destination,
                    fee: oldRecord.fee,
                    status: oldRecord.status,
                    isOutgoing: oldRecord.isOutgoing,
                    type: oldRecord.type,
                    date: oldRecord.date,
                    tokenTransfers: oldRecord.tokenTransfers,
                    nonce: oldRecord.nonce
                )
            } else {
                append(record)
            }
        }
    }
}
