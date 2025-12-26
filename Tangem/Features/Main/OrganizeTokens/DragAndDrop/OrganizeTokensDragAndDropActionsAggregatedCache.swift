//
//  OrganizeTokensDragAndDropActionsAggregatedCache.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// Provides individual, section-specific caches for drag and drop actions.
final class OrganizeTokensDragAndDropActionsAggregatedCache {
    private var innerCaches: [ObjectIdentifier: OrganizeTokensDragAndDropActionsCache] = [:]

    func dragAndDropActionsCache(
        for outerSectionViewModel: OrganizeTokensListOuterSectionViewModel
    ) -> OrganizeTokensDragAndDropActionsCache {
        let cacheKey = outerSectionViewModel.cacheKey

        if let existingCache = innerCaches[cacheKey] {
            return existingCache
        }

        let newCache = OrganizeTokensDragAndDropActionsCache()
        innerCaches[cacheKey] = newCache

        return newCache
    }

    func purgeCache(using outerSectionViewModels: [OrganizeTokensListOuterSectionViewModel]) {
        let cacheKeys = outerSectionViewModels
            .map(\.cacheKey)
            .toSet()

        innerCaches.removeAll { !cacheKeys.contains($0.key) }
    }

    func reset() {
        innerCaches.values.forEach { $0.reset() }
    }
}
