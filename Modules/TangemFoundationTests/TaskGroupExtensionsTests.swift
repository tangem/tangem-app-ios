//
//  TaskGroupExtensionsTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Testing

@Suite("Tests for extensions from the TaskGroup+.swift file")
struct TaskGroupExtensionsTests {
    @Test(
        "Test `TaskGroup.executeKeepingOrder` helper method",
        arguments: [
            [3, 1, 2, 5, 4, 2, 1],
            [],
            [1, 2, 3, 4],
            [Int](repeating: Int.random(in: 0 ... 5), count: 100),
        ]
    )
    func testExecuteKeepingOrder(numbers: [Int]) async throws {
        let expectedResult = numbers.map(String.init)

        let givenResult = await TaskGroup.executeKeepingOrder(items: numbers, action: processItem)
        #expect(givenResult == expectedResult)
    }

    @Test(
        "Test `TaskGroup.tryExecuteKeepingOrder` helper method",
        arguments: [
            [3, 1, 2, 5, 4, 2, 1],
            [],
            [1, 2, 3, 4],
            [Int](repeating: Int.random(in: 0 ... 5), count: 100),
        ]
    )
    func testTryExecuteKeepingOrder(numbers: [Int]) async throws {
        let expectedResult = numbers.map(String.init)

        let givenResult = try await TaskGroup.tryExecuteKeepingOrder(items: numbers, action: tryProcessItem)
        #expect(givenResult == expectedResult)
    }

    private func processItem(_ item: Int) async -> String {
        return await Task.detached {
            try? await Task.sleep(for: .milliseconds(item * 100))
            return "\(item)"
        }.value
    }

    private func tryProcessItem(_ item: Int) async throws -> String {
        return try await Task.detached {
            try await Task.sleep(for: .milliseconds(item * 100))
            return "\(item)"
        }.value
    }
}
