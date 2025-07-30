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
        /// Initial input.
        case normal
        /// Input attempts before transitioning to lock with timeout duration.
        case beforeLock(remaining: Int)
        /// Input attempts before transitioning to warning lock with timeout duration.
        case beforeWarning(remaining: Int)
        /// Input attempts before delete.
        case beforeDelete(remaining: Int)
    }

    enum LockedState: Equatable {
        /// Timeout waiting timer before transitioning to warning lock.
        case beforeWarning(remaining: Int, timeout: TimeInterval)
        /// Timeout waiting timer before delete.
        case beforeDelete(remaining: Int, timeout: TimeInterval)
    }
}
