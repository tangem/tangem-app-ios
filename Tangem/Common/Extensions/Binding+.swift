//
//  Binding+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

extension Binding {
    init<Root: AnyObject>(
        root: Root,
        default value: Value,
        get: @escaping (Root) -> Value,
        set: @escaping (Root, Value) -> Void
    ) {
        self.init { [weak root] in
            guard let root else {
                assertionFailure("Root is released")
                return value
            }

            return get(root)
        } set: { [weak root] newValue in
            guard let root else {
                assertionFailure("Root is released")
                return
            }

            return set(root, newValue)
        }
    }
}
