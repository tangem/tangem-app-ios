//
//  FeedRecentQuery.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct FeedRecentQuery: Identifiable, Hashable {
    let value: String

    var id: String { value }
}
