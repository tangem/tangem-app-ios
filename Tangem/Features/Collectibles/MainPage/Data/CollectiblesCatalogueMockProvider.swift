//
//  CollectiblesCatalogueMockProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct CollectiblesCatalogueMockProvider: CollectiblesLoresProvider, CollectiblesPacksProvider {
    private let loresProvider = CollectiblesLoresMockProvider()
    private let packsProvider = CollectiblesPacksMockProvider()

    func load() async throws -> CollectiblesLoreCatalogue {
        try await loresProvider.load()
    }

    func load(loreID: String?, query: String, cursor: String?) async throws -> CollectiblesPacksPage {
        try await packsProvider.load(loreID: loreID, query: query, cursor: cursor)
    }
}
