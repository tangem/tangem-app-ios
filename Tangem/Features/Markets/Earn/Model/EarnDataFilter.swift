//
//  EarnDataFilter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct EarnDataFilter: Hashable {
    let type: EarnFilterType
    let networkIds: [String]?

    init(type: EarnFilterType = .all, networkIds: [String]? = nil) {
        self.type = type
        self.networkIds = networkIds
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine((networkIds ?? []).sorted().joined(separator: ","))
    }

    static func == (lhs: EarnDataFilter, rhs: EarnDataFilter) -> Bool {
        lhs.type == rhs.type && normalizedNetworkIds(lhs.networkIds) == normalizedNetworkIds(rhs.networkIds)
    }

    private static func normalizedNetworkIds(_ ids: [String]?) -> [String] {
        (ids ?? []).sorted()
    }
}
