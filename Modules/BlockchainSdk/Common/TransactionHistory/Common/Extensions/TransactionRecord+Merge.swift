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
    /// - Returns: The hashes of records that were zipped into existing entries (for caller-side logging).
    @discardableResult
    mutating func appendMerging(_ newRecords: [TransactionRecord]) -> [String] {
        var zippedHashes: [String] = []

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
                    isFromYieldContract: oldRecord.isFromYieldContract,
                    nonce: oldRecord.nonce,
                    extraInfo: conditionalCast(oldRecord.extraInfo, to: TransactionRecord.ExtraInfoType.self)
                )
                zippedHashes.append(record.hash)
            } else {
                append(record)
            }
        }

        return zippedHashes
    }

    /// Workaround for casting to marker protocols, see https://forums.swift.org/t/82070 for details.
    @inline(__always)
    private func conditionalCast<T, U>(_ value: T, to: U.Type) -> U? {
        return value as? U
    }
}
