//
//  EarnRewardSubtitle.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Section subtitle with an optional highlighted chip inside: "{prefix} {chip} {suffix}".
struct EarnRewardSubtitle: Equatable {
    let prefix: String
    let chip: Chip?
    let suffix: String?
}

extension EarnRewardSubtitle {
    /// `fiat` is the bare amount (the view adds "/year" and masks it); `rate` is never masked.
    enum Chip: Equatable {
        case fiat(String)
        case rate(String)
    }
}
