//
//  CollectiblesGeoblockMockProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct CollectiblesGeoblockMockProvider: CollectiblesGeoblockProvider {
    func load() async throws -> CollectiblesRegionStatus {
        .allowed
    }
}
