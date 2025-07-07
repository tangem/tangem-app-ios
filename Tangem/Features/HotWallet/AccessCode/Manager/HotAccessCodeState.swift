//
//  HotAccessCodeState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum HotAccessCodeState: Equatable {
    /// Access code is available for user input.
    case available(AvailableState)
    /// Access code is successfully validated.
    case valid
    /// Access code input is locked for time interval.
    case locked(LockedState)
    /// Access code is unavailable for user input.
    case unavailable

    enum AvailableState: Equatable {
        case normal
        case beforeLock(remaining: Int)
        case beforeWarning(remaining: Int)
        case beforeDelete(remaining: Int)
    }

    enum LockedState: Equatable {
        case beforeWarning(remaining: Int, timeout: TimeInterval)
        case beforeDelete(remaining: Int, timeout: TimeInterval)
    }
}
