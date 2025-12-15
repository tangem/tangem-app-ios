//
//  OrganizeTokensDragAndDropActionsAggregatedCache.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class OrganizeTokensDragAndDropActionsAggregatedCache {
    private var innerCaches: [AnyHashable: OrganizeTokensDragAndDropActionsCache] = [:]

    func cache(forAccountID accountID: AnyHashable) -> OrganizeTokensDragAndDropActionsCache {
        if let cache = innerCaches[accountID] {
            return cache
        }

        let newCache = OrganizeTokensDragAndDropActionsCache()
        innerCaches[accountID] = newCache
        return newCache
    }
    
    func invalidateCaches(notIn validAccountIDs: Set<AnyHashable>) {
        innerCaches = innerCaches.filter { validAccountIDs.contains($0.key) }
    }
    
    func resetAll() {
        innerCaches.values.forEach { $0.reset() }
    }
}
