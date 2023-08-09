//
//  Transaction+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

extension Transaction {
    /// Based on this https://developer.apple.com/forums/thread/727858 advice from an Apple framework engineer.
    static func withoutAnimations() -> Self {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        return transaction
    }
}
