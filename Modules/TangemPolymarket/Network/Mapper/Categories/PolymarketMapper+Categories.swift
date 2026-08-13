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
            iconURL: url(from: dto.icon)
        )
    }
}
