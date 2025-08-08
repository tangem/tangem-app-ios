//
//  HotAccessCodeConfiguration.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct HotAccessCodeConfiguration {
    /// Limit of failed attempts before the access code is locked.
    let attemptsToLockLimit: Int
    /// Limit of failed attempts after which deletion warning starts.
    let attemptsBeforeWarningLimit: Int
    /// Limit of failed attempts before deleting the wallet.
    let attemptsBeforeDeleteLimit: Int
    /// Timeout interval of locked input.
    let lockedTimeout: TimeInterval
}

// MARK: - Configurations

extension HotAccessCodeConfiguration {
    static let `default` = HotAccessCodeConfiguration(
        attemptsToLockLimit: 5,
        attemptsBeforeWarningLimit: 20,
        attemptsBeforeDeleteLimit: 30,
        lockedTimeout: 60
    )

    #if DEBUG
    static let demo = HotAccessCodeConfiguration(
        attemptsToLockLimit: 3,
        attemptsBeforeWarningLimit: 5,
        attemptsBeforeDeleteLimit: 10,
        lockedTimeout: 5
    )
    #endif
}
