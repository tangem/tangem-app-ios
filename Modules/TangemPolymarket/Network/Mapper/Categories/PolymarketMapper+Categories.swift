//
//  PolymarketMapper+Categories.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

extension PolymarketMapper {
    func mapCategory(_ dto: PolymarketDTO.Category) -> PolymarketCategory {
        PolymarketCategory(
            id: dto.id,
            label: dto.label,
            icon: dto.icon.flatMap(PolymarketCategoryIcon.init(rawValue:)),
            subcategories: mapSubcategories(of: dto),
            filters: (dto.filters ?? []).map(PolymarketCategoryFilter.init(rawValue:))
        )
    }
}

// MARK: - Private

private extension PolymarketMapper {
    func mapSubcategories(of dto: PolymarketDTO.Category) -> [PolymarketCategory] {
        var seenIDs: Set<Int> = [dto.id]

        return (dto.subcategories ?? [])
            .filter { seenIDs.insert($0.id).inserted }
            .map(mapCategory)
    }
}
