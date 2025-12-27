//
//  Lock.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import os.lock

public final class Lock {
    private let isRecursive: Bool

    /// - Note: Implicitly unwrapped optional to avoid boxing overhead with Swift protocols.
    private var recursiveLock: NSRecursiveLock!

    /// - Note: Implicitly unwrapped optional to avoid boxing overhead with Swift protocols.
    private var nonRecursiveLock: OSAllocatedUnfairLock<Void>!

    /// - Warning: Think twice before using recursive lock, as it has a much higher overhead than non-recursive one.
    public init(isRecursive: Bool) {
        self.isRecursive = isRecursive

        if isRecursive {
            recursiveLock = NSRecursiveLock()
        } else {
            nonRecursiveLock = OSAllocatedUnfairLock()
        }
    }

    public func withLock<R>(_ body: () throws -> R) rethrows -> R {
        if isRecursive {
            return try recursiveLock.withLock(body)
        } else {
            return try nonRecursiveLock.withLockUnchecked(body)
        }
    }

    public func callAsFunction<R>(_ body: () throws -> R) rethrows -> R {
        try withLock(body)
    }
}
