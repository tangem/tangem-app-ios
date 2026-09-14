//
//  TransactionRecord+Merge.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public extension Array where Element == TransactionRecord {
    /// Appends new records, zipping `source`/`destination` of any record that already exists by `hash` + `index`.
    ///
    /// - Parameters:
    ///   - newRecords: records to append.
    ///   - recordIDToIndex: maps a record's `id` to its position for O(1) lookup. Must be persisted alongside the array across calls.
    /// - Returns: The hashes of records that were zipped into existing entries (for caller-side logging).
    @discardableResult
    mutating func appendMerging(
        _ newRecords: [TransactionRecord],
        recordIDToIndex: inout [TransactionRecord.ID: Int]
    ) -> [String] {
        var zippedHashes: [String] = []

        for newRecord in newRecords {
            if let foundRecordIndex = recordIDToIndex[newRecord.id] {
                let oldRecord = self[foundRecordIndex]
                self[foundRecordIndex] = oldRecord.merged(with: newRecord)
                zippedHashes.append(newRecord.hash)
            } else {
                let indexOfNewRecord = count
                recordIDToIndex[newRecord.id] = indexOfNewRecord
                append(newRecord)
            }
        }

        return zippedHashes
    }
}

private extension TransactionRecord {
    func merged(with newRecord: TransactionRecord) -> TransactionRecord {
        TransactionRecord(
            hash: newRecord.hash,
            index: newRecord.index,
            source: source + newRecord.source,
            destination: destination + newRecord.destination,
            fee: fee,
            status: status,
            isOutgoing: isOutgoing,
            type: type,
            date: date,
            tokenTransfers: tokenTransfers,
            isFromYieldContract: isFromYieldContract,
            nonce: nonce,
            extraInfo: conditionalCast(extraInfo, to: TransactionRecord.ExtraInfoType.self)
        )
    }

    /// Workaround for casting to marker protocols, see https://forums.swift.org/t/82070 for details.
    @inline(__always)
    private func conditionalCast<T, U>(_ value: T, to: U.Type) -> U? {
        return value as? U
    }
}
