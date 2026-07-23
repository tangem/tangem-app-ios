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
    let chip: String?
    let suffix: String?
}
