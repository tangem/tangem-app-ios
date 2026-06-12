//
//  NonEmptyArray.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// An array guaranteed to hold at least one element by construction.
struct NonEmptyArray<Element> {
    private(set) var elements: [Element]

    /// The first element, always present.
    var head: Element { elements[0] }

    init?(_ elements: [Element]) {
        guard !elements.isEmpty else { return nil }
        self.elements = elements
    }

    init(head: Element, tail: [Element] = []) {
        elements = [head] + tail
    }
}

extension NonEmptyArray: RandomAccessCollection {
    var startIndex: Int { elements.startIndex }
    var endIndex: Int { elements.endIndex }
    func index(after i: Int) -> Int { elements.index(after: i) }
    subscript(position: Int) -> Element { elements[position] }
}

extension NonEmptyArray: Equatable where Element: Equatable {}

extension NonEmptyArray: Hashable where Element: Hashable {}
