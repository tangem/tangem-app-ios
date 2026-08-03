//
//  Sequence+.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public extension Sequence {
    /// Creates a new dictionary whose keys are defined by the given keypath and whose values
    /// are the first elements of the sequence that have these keys.
    func keyedFirst<T>(by keyPath: KeyPath<Element, T>) -> [T: Element] where T: Hashable {
        return reduce(into: [:]) { result, element in
            let key = element[keyPath: keyPath]

            if result[key] == nil {
                result[key] = element
            }
        }
    }

    /// Creates a new dictionary whose keys are defined by the given keypath and whose values are
    /// the first elements of the sequence that have these keys.
    func keyedLast<T>(by keyPath: KeyPath<Element, T>) -> [T: Element] where T: Hashable {
        return reduce(into: [:]) { result, element in
            let key = element[keyPath: keyPath]
            result[key] = element
        }
    }

    /// Creates a new dictionary whose keys are computed by the given closure and whose values
    /// are the first elements of the sequence that have these keys.
    func keyedFirst<T>(by key: (Element) -> T) -> [T: Element] where T: Hashable {
        return reduce(into: [:]) { result, element in
            let elementKey = key(element)

            if result[elementKey] == nil {
                result[elementKey] = element
            }
        }
    }

    /// Creates a new dictionary whose keys are computed by the given closure and whose values
    /// are the last elements of the sequence that have these keys.
    func keyedLast<T>(by key: (Element) -> T) -> [T: Element] where T: Hashable {
        return reduce(into: [:]) { result, element in
            result[key(element)] = element
        }
    }

    /// Just a shim for `Dictionary(grouping:by:)`.
    func grouped<T>(by keyPath: KeyPath<Element, T>) -> [T: [Element]] where T: Hashable {
        return Dictionary(grouping: self) { element in
            return element[keyPath: keyPath]
        }
    }

    /// Returns an ordered collection of elements, unique/distinct by property for the given keypath.
    func unique<T>(by keyPath: KeyPath<Element, T>) -> [Element] where T: Hashable {
        var seen: Set<T> = []

        return filter { element in
            let key = element[keyPath: keyPath]
            return seen.insert(key).inserted
        }
    }

    /// Returns an ordered collection of unique/distinct properties of elements for the given keypath.
    func uniqueProperties<T>(_ keyPath: KeyPath<Element, T>) -> [T] where T: Hashable {
        var seen: Set<T> = []

        return compactMap { element in
            let property = element[keyPath: keyPath]
            return seen.insert(property).inserted ? property : nil
        }
    }
}

// MARK: - Sequence + Hashable

public extension Sequence where Element: Hashable {
    /// Just a shim for `Set(_:)`.
    func toSet() -> Set<Element> {
        return Set(self)
    }

    /// Returns an ordered collection of unique/distinct elements.
    func unique() -> [Element] {
        return unique(by: \.self)
    }
}
