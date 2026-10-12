//
//  FeedAccountAvailability.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct FeedAccountAvailability: Equatable {
    let crypto: Bool
    let joint: Bool

    var isAvailable: Bool { crypto }
}
