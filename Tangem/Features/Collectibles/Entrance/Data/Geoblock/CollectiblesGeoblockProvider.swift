//
//  CollectiblesGeoblockProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol CollectiblesGeoblockProvider {
    func load() async throws -> CollectiblesRegionStatus
}

enum CollectiblesRegionStatus {
    case allowed
    case restricted
}
