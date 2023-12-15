//
//  Collection+Concurrency.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

// MARK: - Map

public extension Sequence {
    /// Transform the sequence into an array of new values using
    /// an async closure.
    ///
    /// The closure calls will be performed in order, by waiting for
    /// each call to complete before proceeding with the next one. If
    /// any of the closure calls throw an error, then the iteration
    /// will be terminated and the error rethrown.
    ///
    /// - parameter transform: The transform to run on each element.
    /// - returns: The transformed values as an array. The order of
    ///   the transformed values will match the original sequence.
    /// - throws: Rethrows any error thrown by the passed closure.
    func asyncMap<T>(
        _ transform: (Element) async throws -> T
    ) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            try await values.append(transform(element))
        }

        return values
    }
}

// MARK: - CompactMap

public extension Sequence {
    /// Transform the sequence into an array of new values using
    /// an async closure that returns optional values. Only the
    /// non-`nil` return values will be included in the new array.
    ///
    /// The closure calls will be performed in order, by waiting for
    /// each call to complete before proceeding with the next one. If
    /// any of the closure calls throw an error, then the iteration
    /// will be terminated and the error rethrown.
    ///
    /// - parameter transform: The transform to run on each element.
    /// - returns: The transformed values as an array. The order of
    ///   the transformed values will match the original sequence,
    ///   except for the values that were transformed into `nil`.
    /// - throws: Rethrows any error thrown by the passed closure.
    func asyncCompactMap<T>(
        _ transform: (Element) async throws -> T?
    ) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            guard let value = try await transform(element) else {
                continue
            }

            values.append(value)
        }

        return values
    }
}

// MARK: - FlatMap

public extension Sequence {
    /// Transform the sequence into an array of new values using
    /// an async closure that returns sequences. The returned sequences
    /// will be flattened into the array returned from this function.
    ///
    /// The closure calls will be performed in order, by waiting for
    /// each call to complete before proceeding with the next one. If
    /// any of the closure calls throw an error, then the iteration
    /// will be terminated and the error rethrown.
    ///
    /// - parameter transform: The transform to run on each element.
    /// - returns: The transformed values as an array. The order of
    ///   the transformed values will match the original sequence,
    ///   with the results of each closure call appearing in-order
    ///   within the returned array.
    /// - throws: Rethrows any error thrown by the passed closure.
    func asyncFlatMap<T: Sequence>(
        _ transform: (Element) async throws -> T
    ) async rethrows -> [T.Element] {
        var values = [T.Element]()

        for element in self {
            try await values.append(contentsOf: transform(element))
        }

        return values
    }
}

// MARK: - Sort

public extension Sequence {
    /// Transform the sequence into an array of new values using
    /// an async closure.
    ///
    /// The closure calls will be performed in order, by waiting for
    /// each call to complete before proceeding with the next one. If
    /// any of the closure calls throw an error, then the iteration
    /// will be terminated and the error rethrown.
    ///
    /// - parameter transform: The transform to run on each element.
    /// - returns: The transformed values as an array. The order of
    ///   the transformed values will match the original sequence.
    /// - throws: Rethrows any error thrown by the passed closure.
    func asyncSorted<T>(
        sort areInIncreasingOrder: (T, T) throws -> Bool,
        by value: (Element) async throws -> T
    ) async rethrows -> [Element] {
        var values = [(Element, T)]()

        for element in self {
            try await values.append((element, value(element)))
        }

        return try values.sorted(by: { try areInIncreasingOrder($0.1, $1.1) }).map { $0.0 }
    }
}
