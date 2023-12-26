//
//  Array+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

extension Array where Element: Hashable {
    mutating func insert(_ element: Element) {
        var set = toSet()
        set.insert(element)
        self = Array(set)
    }

    mutating func remove(_ element: Element) {
        var set = toSet()
        set.remove(element)
        self = Array(set)
    }

    func toSet() -> Set<Element> {
        return Set(self)
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
