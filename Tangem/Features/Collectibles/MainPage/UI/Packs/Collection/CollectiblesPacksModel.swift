//
//  CollectiblesPacksModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

@MainActor
final class CollectiblesPacksModel {
    // MARK: - Properties

    private let provider: any CollectiblesPacksProvider

    private var loreID: String?
    private var query = ""
    private var cursor: String?
    private var packs: [CollectiblesPack] = []
    private var hasMore = false
    private var cache: [String?: Snapshot] = [:]

    /// Drives the empty and failed copy: the wording differs once a query is what produced the result.
    var hasQuery: Bool {
        query.trimmingCharacters(in: .whitespacesAndNewlines).isNotEmpty
    }

    // MARK: - Init

    init(provider: any CollectiblesPacksProvider) {
        self.provider = provider
    }

    // MARK: - Methods

    func switchLore(_ loreID: String?) -> Catalogue? {
        self.loreID = loreID
        query = ""

        guard let snapshot = cache[loreID] else {
            resetPagination()
            return nil
        }

        restore(snapshot)
        return catalogue()
    }

    func setQuery(_ query: String) {
        self.query = query
    }

    func load() async throws -> Catalogue {
        let page = try await provider.load(loreID: loreID, query: query, cursor: nil)
        try Task.checkCancellation()

        packs = page.packs
        cursor = page.cursor
        hasMore = page.hasNext && page.cursor != nil
        cacheCatalogue()

        return catalogue()
    }

    func loadMore() async throws -> Catalogue {
        let previousCursor = cursor
        let page = try await provider.load(loreID: loreID, query: query, cursor: previousCursor)
        try Task.checkCancellation()

        cursor = page.cursor
        hasMore = page.hasNext && page.cursor != nil && page.cursor != previousCursor

        let knownIDs = Set(packs.map(\.id))
        packs += page.packs.filter { !knownIDs.contains($0.id) }
        cacheCatalogue()

        return catalogue()
    }

    func reset(loreID: String?) {
        self.loreID = loreID
        query = ""
        packs = []
        resetPagination()
    }

    func seed(_ snapshot: Snapshot) {
        query = ""
        restore(snapshot)
    }

    func snapshot() -> Snapshot {
        Snapshot(packs: packs, cursor: cursor, hasMore: hasMore)
    }

    func pack(withID id: String) -> CollectiblesPack? {
        packs.first { $0.id == id }
    }

    func catalogue() -> Catalogue {
        Catalogue(packs: packs, hasMore: hasMore)
    }
}

// MARK: - Entities

extension CollectiblesPacksModel {
    struct Catalogue {
        let packs: [CollectiblesPack]
        let hasMore: Bool
    }

    struct Snapshot {
        let packs: [CollectiblesPack]
        let cursor: String?
        let hasMore: Bool
    }
}

// MARK: - Private logic

private extension CollectiblesPacksModel {
    func resetPagination() {
        cursor = nil
        hasMore = false
    }

    func restore(_ snapshot: Snapshot) {
        packs = snapshot.packs
        cursor = snapshot.cursor
        hasMore = snapshot.hasMore
    }

    func cacheCatalogue() {
        guard !hasQuery else { return }

        cache[loreID] = snapshot()
    }
}
