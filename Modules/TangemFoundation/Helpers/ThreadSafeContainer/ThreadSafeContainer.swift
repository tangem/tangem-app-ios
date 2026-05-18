//
//  ThreadSafeContainer.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/// Provides `multiple readers - single writer` semantics for underlying `value`.
/// It's most useful with Swift native collections like `Array`, `Dictionary`, etc.
/// This type is fully `Sendable` due to internal synchronization using Dispatch queues.
@available(*, noasync, message: "Do not use from async context since sync reads/writes block the cooperative thread pool. Migrate to an actor instead.")
@dynamicMemberLookup
public final class ThreadSafeContainer<Value>: @unchecked Sendable {
    @available(*, noasync, message: "Do not use from async context since sync reads/writes block the cooperative thread pool. Migrate to an actor instead.")
    public subscript<T>(dynamicMember keyPath: KeyPath<Value, T>) -> T {
        accessQueue.sync { value[keyPath: keyPath] }
    }

    private let accessQueue = DispatchQueue(
        label: "com.tangem.ThreadSafeContainer.\(UUID().uuidString)",
        attributes: .concurrent
    )

    private var value: Value

    @available(*, noasync, message: "Do not use from async context since sync reads/writes block the cooperative thread pool. Migrate to an actor instead.")
    public init(_ value: Value) {
        self.value = value
    }

    /// Read-only access to the wrapped value.
    @available(*, noasync, message: "Do not use from async context since sync reads/writes block the cooperative thread pool. Migrate to an actor instead.")
    public func read() -> Value {
        accessQueue.sync { value }
    }

    /// Read-write (with atomicity within the body of the closure) access to the wrapped value.
    @available(*, noasync, message: "Do not use from async context since sync reads/writes block the cooperative thread pool. Migrate to an actor instead.")
    public func mutate(_ body: (_ value: inout Value) -> Void) {
        accessQueue.sync(flags: .barrier) { body(&self.value) }
    }
}

// MARK: - CustomStringConvertible protocol conformance

extension ThreadSafeContainer: CustomStringConvertible {
    @available(*, noasync, message: "Do not use from async context since sync reads/writes block the cooperative thread pool. Migrate to an actor instead.")
    public var description: String {
        String(describing: value)
    }
}
