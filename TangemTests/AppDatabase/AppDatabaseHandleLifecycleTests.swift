//
//  AppDatabaseHandleLifecycleTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB
import TangemFoundation
import Testing
@testable import Tangem

@Suite("AppDatabase handle lifecycle", .tags(.appDatabase))
struct AppDatabaseHandleLifecycleTests {
    @Test("Factory runs exactly once across repeated accesses")
    func factoryRunsOnceAcrossRepeatedAccesses() throws {
        let factoryCallCount = OSAllocatedUnfairLock(initialState: 0)
        let appDatabase = AppDatabase { _ in
            factoryCallCount { $0 += 1 }

            return try DatabaseQueue()
        }

        _ = try appDatabase.databaseHandle
        _ = try appDatabase.databaseHandle
        _ = try appDatabase.databaseHandle

        #expect(factoryCallCount { $0 } == 1)
    }

    @Test("Factory runs exactly once under concurrent access")
    func factoryRunsOnceUnderConcurrentAccess() async throws {
        let factoryCallCount = OSAllocatedUnfairLock(initialState: 0)
        let appDatabase = AppDatabase { _ in
            factoryCallCount { $0 += 1 }

            return try DatabaseQueue()
        }

        try await withThrowingTaskGroup(of: Void.self) { taskGroup in
            for _ in 0 ..< 16 {
                taskGroup.addTask {
                    _ = try appDatabase.databaseHandle
                }
            }

            try await taskGroup.waitForAll()
        }

        #expect(factoryCallCount { $0 } == 1)
    }

    @Test("A throwing factory propagates the error and the next access retries")
    func throwingFactoryPropagatesErrorAndRetries() throws {
        struct FactoryError: Error {}

        let factoryCallCount = OSAllocatedUnfairLock(initialState: 0)
        let appDatabase = AppDatabase { _ in
            let callNumber = factoryCallCount { state in
                state += 1

                return state
            }

            if callNumber == 1 {
                throw FactoryError()
            }

            return try DatabaseQueue()
        }

        #expect(throws: FactoryError.self) {
            _ = try appDatabase.databaseHandle
        }

        _ = try appDatabase.databaseHandle

        #expect(factoryCallCount { $0 } == 2)
    }
}
