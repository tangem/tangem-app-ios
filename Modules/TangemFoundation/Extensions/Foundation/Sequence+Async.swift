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
        typealias IntermediateElement = (index: Int, element: T)

        return try await withThrowingTaskGroup(of: IntermediateElement.self) { group in
            // `Sequence` does not conform to `Collection`, so we create indices manually
            for (index, element) in zip(0..., self) {
                group.addTask {
                    return try await (index, transform(element))
                }
            }

            return try await group
                .reduce(into: []) { $0.append($1) }
                .sorted(by: \.index)
                .map(\.element)
        }
    }

    /// - Warning: Do not use on sequences with large number of elements, as it may create too many sleeping tasks simultaneously.
    /// - [REDACTED_TODO_COMMENT]
    /// for example of batching implementation).
    func asyncCompactMap<T>(_ transform: @escaping (Element) async throws -> T?) async rethrows -> [T] {
        typealias IntermediateElement = (index: Int, element: T)

        return try await withThrowingTaskGroup(of: IntermediateElement?.self) { group in
            // `Sequence` does not conform to `Collection`, so we create indices manually
            for (index, element) in zip(0..., self) {
                group.addTask {
                    if let value = try await transform(element) {
                        return (index, value)
                    }

                    // Discarding nil elements early by returning nil
                    return nil
                }
            }

            return try await group
                .reduce(into: [IntermediateElement]()) { partialResult, element in
                    // Unwrapping optional elements here instead of using a separate `compactMap` step
                    if let element {
                        partialResult.append(element)
                    }
                }
                .sorted(by: \.index)
                .map(\.element)
        }
    }

    /// - Warning: Do not use on sequences with large number of elements, as it may create too many sleeping tasks simultaneously.
    /// - [REDACTED_TODO_COMMENT]
    /// for example of batching implementation).
    func asyncFlatMap<T: Sequence>(_ transform: @escaping (Element) async throws -> T) async rethrows -> [T.Element] {
        typealias IntermediateElement = (index: Int, element: T)

        return try await withThrowingTaskGroup(of: IntermediateElement.self) { group in
            // `Sequence` does not conform to `Collection`, so we create indices manually
            for (index, element) in zip(0..., self) {
                group.addTask {
                    return try await (index, transform(element))
                }
            }

            return try await group
                .reduce(into: []) { $0.append($1) }
                .sorted(by: \.index)
                .flatMap(\.element)
        }
    }

    /// - Warning: Do not use on sequences with large number of elements, as it may create too many sleeping tasks simultaneously.
    /// - [REDACTED_TODO_COMMENT]
    /// for example of batching implementation).
    func asyncFilter(_ isIncluded: @escaping (Element) async throws -> Bool) async rethrows -> [Element] {
        typealias IntermediateElement = (index: Int, element: Element)

        return try await withThrowingTaskGroup(of: IntermediateElement?.self) { group in
            // `Sequence` does not conform to `Collection`, so we create indices manually
            for (index, element) in zip(0..., self) {
                group.addTask {
                    if try await isIncluded(element) {
                        return (index, element)
                    }

                    // Discarding filtered out elements early by returning nil
                    return nil
                }
            }

            return try await group
                .reduce(into: [IntermediateElement]()) { partialResult, element in
                    // Unwrapping optional elements here instead of using a separate `compactMap` step
                    if let element {
                        partialResult.append(element)
                    }
                }
                .sorted(by: \.index)
                .map(\.element)
        }
    }

    /// - Warning: Do not use on sequences with large number of elements, as it may create too many sleeping tasks simultaneously.
    /// - [REDACTED_TODO_COMMENT]
    /// for example of batching implementation).
    func asyncSorted<T>(
        sort areInIncreasingOrder: (T, T) throws -> Bool,
        by value: @escaping (Element) async throws -> T
    ) async rethrows -> [Element] {
        typealias IntermediateElement = (element: Element, value: T)

        return try await withThrowingTaskGroup(of: IntermediateElement.self) { group in
            for element in self {
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
