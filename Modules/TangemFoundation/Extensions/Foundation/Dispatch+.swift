//
//  Dispatch+.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

@inline(__always)
public func ensureOnMainQueue() {
    guard AppEnvironment.current.isAlphaOrBetaOrDebug else {
        return
    }

    dispatchPrecondition(condition: .onQueue(.main))
}

@inline(__always)
public func ensureNotOnMainQueue() {
    guard AppEnvironment.current.isAlphaOrBetaOrDebug else {
        return
    }

    dispatchPrecondition(condition: .notOnQueue(.main))
}
