//
//  Buildable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public protocol Buildable {
    func map(_ closure: (inout Self) -> Void) -> Self
}

public extension Buildable {
    func map(_ closure: (inout Self) -> Void) -> Self {
        var copy = self
        closure(&copy)
        return copy
    }
}
