//
//  WeakRef.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public final class WeakRef<T: AnyObject> {
    public weak var value: T?

    public init(_ value: T) {
        self.value = value
    }
}
