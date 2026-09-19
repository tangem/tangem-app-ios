//
//  Array+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

/// Set-like membership helpers for arrays that are used as ordered, duplicate-free collections.
///
/// Both operations preserve the relative order of the elements that stay in the array. A `Set` round-trip
/// (`Array(Set(self))`) would shuffle them in a per-process-random order, which is unwanted for arrays
/// whose order is observable (persisted to `UserDefaults`, published via Combine, or forwarded to
/// order-sensitive consumers).
extension Array where Element: Equatable {
    /// Appends `element` unless an equal element is already present.
    mutating func insert(_ element: Element) {
        if !contains(element) {
            append(element)
        }
    }

    /// Removes every element equal to `element`, keeping the remaining elements in place.
    mutating func remove(_ element: Element) {
        removeAll { $0 == element }
    }
}

extension Array {
    func toDictionary<Key: Hashable>(keyedBy keyPath: KeyPath<Element, Key>, useLatestValue: Bool = true) -> [Key: Element] {
        reduce(into: [:]) {
            if useLatestValue {
                $0[$1[keyPath: keyPath]] = $1
                return
            }

            guard $0[$1[keyPath: keyPath]] == nil else {
                return
            }

            $0[$1[keyPath: keyPath]] = $1
        }
    }
}
