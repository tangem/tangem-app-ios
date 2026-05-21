//
//  OSAllocatedUnfairLock+.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

@_exported import os.lock

public extension OSAllocatedUnfairLock {
    @inlinable
    @inline(__always)
    func callAsFunction<R>(_ body: () throws -> R) rethrows -> R {
        return try withLockUnchecked { _ in
            return try body()
        }
    }

    @inlinable
    @inline(__always)
    func callAsFunction<R>(_ body: (_ state: inout State) throws -> R) rethrows -> R {
        return try withLockUnchecked { state in
            return try body(&state)
        }
    }
}
