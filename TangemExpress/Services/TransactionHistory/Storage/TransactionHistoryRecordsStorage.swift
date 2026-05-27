//
//  TransactionHistoryRecordsStorage.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public protocol TransactionHistoryRecordsStorage<Record>: Sendable {
    associatedtype Record: TransactionHistoryRecord

    var records: [Record] { get async }
    var recordsUpdates: AsyncStream<[Record]> { get }

    func updateOrAppend(_ records: [Record]) async
    func clear() async
}
