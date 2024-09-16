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
    #if ALPHA || BETA || DEBUG
    dispatchPrecondition(condition: .onQueue(.main))
    #endif // ALPHA || BETA || DEBUG
}

@inline(__always)
public func ensureNotOnMainQueue() {
    #if ALPHA || BETA || DEBUG
    dispatchPrecondition(condition: .notOnQueue(.main))
    #endif // ALPHA || BETA || DEBUG
}
