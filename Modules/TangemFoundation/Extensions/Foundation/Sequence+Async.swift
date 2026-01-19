//
//  Sequence+Async.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

public extension Sequence {
    /// - Warning: Do not use on sequences with large number of elements, as it may create too many sleeping tasks simultaneously.
    /// - [REDACTED_TODO_COMMENT]
    /// for example of batching implementation).
    func asyncMap<T>(_ transform: @escaping (Element) async throws -> T) async rethrows -> [T] {
        // Creating a separate array of elements to have a stable backing storage and multipass iteration guarantee
        // (since `Sequence` can have vastly different implementations under the hood)
        let elements = Array(self)

        return try await TaskGroup
            .tryExecuteKeepingOrder(items: elements) { element in
                return try await transform(element)
            }
    }

    /// - Warning: Do not use on sequences with large number of elements, as it may create too many sleeping tasks simultaneously.
    /// - [REDACTED_TODO_COMMENT]
    /// for example of batching implementation).
    func asyncCompactMap<T>(_ transform: @escaping (Element) async throws -> T?) async rethrows -> [T] {
        // Creating a separate array of elements to have a stable backing storage and multipass iteration guarantee
        // (since `Sequence` can have vastly different implementations under the hood)
        let elements = Array(self)

        return try await TaskGroup
            .tryExecuteKeepingOrder(items: elements) { element in
                if let value = try await transform(element) {
                    return value
                }

                // Discarding nil elements early by returning nil
                return nil
            }
            .compactMap { $0 }
    }

    /// - Warning: Do not use on sequences with large number of elements, as it may create too many sleeping tasks simultaneously.
    /// - [REDACTED_TODO_COMMENT]
    /// for example of batching implementation).
    func asyncFlatMap<T: Sequence>(_ transform: @escaping (Element) async throws -> T) async rethrows -> [T.Element] {
        // Creating a separate array of elements to have a stable backing storage and multipass iteration guarantee
        // (since `Sequence` can have vastly different implementations under the hood)
        let elements = Array(self)

        return try await TaskGroup
            .tryExecuteKeepingOrder(items: elements) { element in
                return try await transform(element)
            }
            .flatMap { $0 }
    }

    /// - Warning: Do not use on sequences with large number of elements, as it may create too many sleeping tasks simultaneously.
    /// - [REDACTED_TODO_COMMENT]
    /// for example of batching implementation).
    func asyncFilter(_ isIncluded: @escaping (Element) async throws -> Bool) async rethrows -> [Element] {
        // Creating a separate array of elements to have a stable backing storage and multipass iteration guarantee
        // (since `Sequence` can have vastly different implementations under the hood)
        let elements = Array(self)

        return try await TaskGroup
            .tryExecuteKeepingOrder(items: elements) { element in
                if try await isIncluded(element) {
                    return element
                }

                // Discarding filtered out elements early by returning nil
                return nil
            }
            .compactMap { $0 }
    }

    /// - Warning: Do not use on sequences with large number of elements, as it may create too many sleeping tasks simultaneously.
    /// - [REDACTED_TODO_COMMENT]
    /// for example of batching implementation).
    func asyncSorted<T>(
        sort areInIncreasingOrder: (T, T) throws -> Bool,
        by value: @escaping (Element) async throws -> T
    ) async rethrows -> [Element] {
        typealias IntermediateElement = (element: Element, value: T)

        // Creating a separate array of elements to have a stable backing storage and multipass iteration guarantee
        // (since `Sequence` can have vastly different implementations under the hood)
        let elements = Array(self)

        return try await withThrowingTaskGroup(of: IntermediateElement.self) { group in
            for element in elements {
                group.addTask {
                    return try await (element, value(element))
                }
            }

            return try await group
                .reduce(into: []) { $0.append($1) }
                .sorted(by: { try areInIncreasingOrder($0.value, $1.value) })
                .map(\.element)
        }
    }
}
