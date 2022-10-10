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
        var set = Set(self)
        set.insert(element)
        self = Array(set)
    }

    mutating func remove(_ element: Element) {
        var set = Set(self)
        set.remove(element)
        self = Array(set)
    }
}
