//
//  ThreadSafeContainer.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/// Provides `multiple readers - single writer` semantics for underlying `value`.
/// It's most useful with Swift native collections like `Array`, `Dictionary`, etc.
public final class ThreadSafeContainer<T> {
    private var _value: T
    public var value: T {
        get { accessQueue.sync { _value }}
        set { accessQueue.async(flags: .barrier) { self._value = newValue }}
    }

    private let accessQueue = DispatchQueue(
        label: "com.tangem.ThreadSafeContainer.\(UUID().uuidString)",
        attributes: .concurrent
    )

    public init(_ value: T) {
        _value = value
    }
}
