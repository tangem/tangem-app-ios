//
//  WeakRef.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public final class WeakRef<T> {
    private weak var object: AnyObject?

    public var value: T? {
        object as? T
    }

    public init(_ value: T) {
        object = value as AnyObject
    }
}
