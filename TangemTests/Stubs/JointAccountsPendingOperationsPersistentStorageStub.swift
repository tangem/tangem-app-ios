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
}
