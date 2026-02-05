//
//  Dispatch+.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

@inlinable
@inline(__always)
public func ensureOnMainQueue() {
    guard AppEnvironment.current.isAlphaOrBetaOrDebug else {
        return
    }

    dispatchPrecondition(condition: .onQueue(.main))
}

@inlinable
@inline(__always)
public func ensureNotOnMainQueue() {
    guard AppEnvironment.current.isAlphaOrBetaOrDebug else {
        return
    }

    dispatchPrecondition(condition: .notOnQueue(.main))
}
