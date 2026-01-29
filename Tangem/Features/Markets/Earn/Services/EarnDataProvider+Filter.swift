//
//  EarnDataProvider+Filter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension EarnDataProvider {
    struct Filter: Hashable, Equatable {
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

        static func == (lhs: Filter, rhs: Filter) -> Bool {
            lhs.type == rhs.type && lhs.networkIds == rhs.networkIds
        }
    }
}
