//
//  TransactionHistoryRecordsWriterStub.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import TangemFoundation
@testable import Tangem

final class TransactionHistoryRecordsWriterStub: TransactionHistoryRecordsWriter {
    private let isFailing: Bool
    private let state = OSAllocatedUnfairLock(initialState: State())

    var savedOperationIds: [[String]] {
        state.withLock { $0.savedOperationIds }
    }

    var writtenResolvers: [any TransactionHistoryRecordsWriteResolver] {
        state.withLock { $0.writtenResolvers }
    }

    init(isFailing: Bool) {
        self.isFailing = isFailing
    }

    func save(_ transactions: [ExchangeTransaction]) async throws {}

    func save(_ transactions: [OnrampTransaction]) async throws {}

    func save(_ items: [JointOperationHistoryItem]) async throws {
        guard !isFailing else {
            throw "The database refused the page"
        }

        state.withLock { $0.savedOperationIds.append(items.map(\.operation.id)) }
    }

    func write(_ resolver: some TransactionHistoryRecordsWriteResolver) async throws {
        state.withLock { $0.writtenResolvers.append(resolver) }
    }
}

// MARK: - Auxiliary types

private extension TransactionHistoryRecordsWriterStub {
    struct State {
        var savedOperationIds: [[String]] = []
        var writtenResolvers: [any TransactionHistoryRecordsWriteResolver] = []
    }
}
