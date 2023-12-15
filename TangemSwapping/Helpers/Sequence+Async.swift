//
//  Sequence+Async.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

public extension Sequence {
    func asyncMap<T>(_ transform: (Element) async throws -> T) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            try await values.append(transform(element))
        }

        return values
    }

    func asyncCompactMap<T>(_ transform: (Element) async throws -> T?) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            if let value = try await transform(element) {
                values.append(value)
            }
        }

        return values
    }

    func asyncFlatMap<T: Sequence>(_ transform: (Element) async throws -> T) async rethrows -> [T.Element] {
        var values = [T.Element]()

        for element in self {
            try await values.append(contentsOf: transform(element))
        }

        return values
    }

    func asyncSorted<T>(sort areInIncreasingOrder: (T, T) throws -> Bool, by value: (Element) async throws -> T) async rethrows -> [Element] {
        var values = [(Element, T)]()

        for element in self {
            try await values.append((element, value(element)))
        }

        return try values.sorted(by: { try areInIncreasingOrder($0.1, $1.1) }).map { $0.0 }
    }
}
