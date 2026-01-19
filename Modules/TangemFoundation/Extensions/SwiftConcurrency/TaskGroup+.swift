//
//  TaskGroup+.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - Void convenience overloads.

public extension TaskGroup {
    /// Executes an async action for each item concurrently and returns results in the original order.
    /// - Parameters:
    ///   - items: The items to process.
    ///   - action: The async work to perform for each item.
    /// - Returns: An array of results ordered to match the input items.
    static func executeKeepingOrder<Item>(items: [Item], action: @escaping (Item) async -> ChildTaskResult) async -> [ChildTaskResult] {
        await withTaskGroup(of: (Int, ChildTaskResult).self) { group in
            for (index, item) in items.enumerated() {
                group.addTask {
                    let processedItem = await action(item)
                    return (index, processedItem)
                }
            }

            var result = [ChildTaskResult?](repeating: nil, count: items.count)

            for await (index, processedItem) in group {
                result[index] = processedItem
            }

            return result.compactMap(\.self)
        }
    }

    /// Executes an async throwing action for each item concurrently and returns results in the original order.
    /// - Parameters:
    ///   - items: The items to process.
    ///   - action: The async throwing work to perform for each item.
    /// - Returns: An array of results ordered to match the input items.
    /// - Throws: Rethrows any error thrown by `action`.
    static func tryExecuteKeepingOrder<Item>(items: [Item], action: @escaping (Item) async throws -> ChildTaskResult) async throws -> [ChildTaskResult] {
        try await withThrowingTaskGroup(of: (Int, ChildTaskResult).self) { group in
            for (index, item) in items.enumerated() {
                group.addTask {
                    let processedItem = try await action(item)
                    return (index, processedItem)
                }
            }

            var result = [ChildTaskResult?](repeating: nil, count: items.count)

            for try await (index, processedItem) in group {
                result[index] = processedItem
            }

            return result.compactMap(\.self)
        }
    }
}

// MARK: - Void convenience overloads.

public extension TaskGroup<Void> {
    /// Executes an async action for each item concurrently.
    /// - Parameters:
    ///   - items: The items to process.
    ///   - action: The async work to perform for each item.
    static func execute<Item>(items: [Item], action: @escaping (Item) async -> Void) async {
        let _: [ChildTaskResult] = await executeKeepingOrder(items: items, action: action)
    }

    /// Executes an async throwing action for each item concurrently.
    /// - Parameters:
    ///   - items: The items to process.
    ///   - action: The async throwing work to perform for each item.
    /// - Throws: Rethrows any error thrown by `action`.
    static func tryExecute<Item>(items: [Item], action: @escaping (Item) async throws -> ChildTaskResult) async throws {
        let _: [ChildTaskResult] = try await tryExecuteKeepingOrder(items: items, action: action)
    }
}
