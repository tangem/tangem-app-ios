//
//  JointAccountsPendingOperationsPersistentStorageStub.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
@testable import Tangem

final class JointAccountsPendingOperationsPersistentStorageStub: JointAccountsPendingOperationsPersistentStorage {
    private let recordsLock: OSAllocatedUnfairLock<[StoredJointAccountPendingOperations]>
    private let didUpdateSubject = PassthroughSubject<Void, Never>()

    var records: [StoredJointAccountPendingOperations] {
        recordsLock.withLock { $0 }
    }

    var didUpdatePublisher: AnyPublisher<Void, Never> {
        didUpdateSubject.eraseToAnyPublisher()
    }

    init(records: [StoredJointAccountPendingOperations] = []) {
        recordsLock = OSAllocatedUnfairLock(initialState: records)
    }

    func getList() -> [StoredJointAccountPendingOperations] {
        records
    }

    func replace(with records: [StoredJointAccountPendingOperations]) throws {
        recordsLock.withLock { $0 = records }
        didUpdateSubject.send()
    }

    func appendNewOrUpdateExisting(_ operation: JointAccountOperation, forCryptoAccountId cryptoAccountId: String) throws {
        edit(operationsForCryptoAccountId: cryptoAccountId) { operations in
            if let index = operations.firstIndex(where: { $0.id == operation.id }) {
                operations[index] = operation
            } else {
                operations.append(operation)
            }
        }
    }

    func remove(operationWithId operationId: String, forCryptoAccountId cryptoAccountId: String) throws {
        edit(operationsForCryptoAccountId: cryptoAccountId) { operations in
            operations.removeAll { $0.id == operationId }
        }
    }

    private func edit(operationsForCryptoAccountId cryptoAccountId: String, _ edit: (inout [JointAccountOperation]) -> Void) {
        recordsLock.withLock { records in
            let index = records.firstIndex(by: cryptoAccountId)
            var operations = index.map { records[$0].operations } ?? []
            edit(&operations)

            switch (index, operations.isEmpty) {
            case (let index?, true):
                records.remove(at: index)
            case (let index?, false):
                records[index] = StoredJointAccountPendingOperations(cryptoAccountId: cryptoAccountId, operations: operations)
            case (nil, true):
                return
            case (nil, false):
                records.append(StoredJointAccountPendingOperations(cryptoAccountId: cryptoAccountId, operations: operations))
            }
        }

        didUpdateSubject.send()
    }
}
