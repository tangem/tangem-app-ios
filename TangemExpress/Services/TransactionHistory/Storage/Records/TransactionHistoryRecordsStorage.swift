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

    func recordsUpdates(for currency: ExpressCurrency) -> AsyncStream<[Record]>

    func updateOrAppend(_ records: [Record]) async throws
    func clear() async throws
}
