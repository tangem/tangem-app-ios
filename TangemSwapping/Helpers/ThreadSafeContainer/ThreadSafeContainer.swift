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
///
/// - ToDo: This is a generic helper, therefore move it into `Core`/`Common`/`Utils`/etc module.
@dynamicMemberLookup
public final class ThreadSafeContainer<Value> {
    public subscript<T>(dynamicMember keyPath: KeyPath<Value, T>) -> T {
        accessQueue.sync { value[keyPath: keyPath] }
    }

    private let accessQueue = DispatchQueue(
        label: "com.tangem.ThreadSafeContainer.\(UUID().uuidString)",
        attributes: .concurrent
    )

    private var value: Value

    public init(_ value: Value) {
        self.value = value
    }

    /// Read-only access to the wrapped value.
    public func read() -> Value {
        accessQueue.sync { value }
    }

    /// Read-write (with atomicity within the body of the closure) access to the wrapped value.
    public func mutate(_ body: @escaping (_ value: inout Value) -> Void) {
        accessQueue.async(flags: .barrier) { body(&self.value) }
    }
}
