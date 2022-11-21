//
//  Setupable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

/// Protocol for customizing UI components
/// Extend your view this protocol and use `map` function for update some property
/// Example: `GroupedNumberTextField`
public protocol Setupable {
    func map(_ closure: (inout Self) -> Void) -> Self
}

public extension Setupable {
    func map(_ closure: (inout Self) -> Void) -> Self {
        var copy = self
        closure(&copy)
        return copy
    }
}
