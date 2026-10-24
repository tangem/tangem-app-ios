//
//  TangemPayDailyLimitState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct TangemPayDailyLimit: Equatable {
    let currentLimit: String
}

enum TangemPayDailyLimitState: Equatable {
    case loading
    case loaded(TangemPayDailyLimit)
    case error
}
