//
//  OrganizeTokensDragAndDropActionsAggregatedCache.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class OrganizeTokensDragAndDropActionsAggregatedCache {
    private var innerCaches: [Int: OrganizeTokensDragAndDropActionsCache] = [:]

    // [REDACTED_TODO_COMMENT]
    func cache(forOuterSectionIndex outerSectionIndex: Int) -> OrganizeTokensDragAndDropActionsCache {
        if let cache = innerCaches[outerSectionIndex] {
            return cache
        }

        let newCache = OrganizeTokensDragAndDropActionsCache()
        innerCaches[outerSectionIndex] = newCache
        return newCache
    }
}
