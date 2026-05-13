//
//  CommonMarketsTokenSearchStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

actor CommonMarketsTokenSearchStorage: MarketsTokenSearchStorage {
    nonisolated var recentItemsPublisher: AnyPublisher<[MarketsTokenSearchRecentItem], Never> {
        recentItemsSubject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private let maxItems = 3
    private let persistentStorage: PersistentStorageProtocol
    private nonisolated let recentItemsSubject: CurrentValueSubject<[MarketsTokenSearchRecentItem], Never>

    init(persistentStorage: PersistentStorageProtocol) {
        self.persistentStorage = persistentStorage

        let queries: [String] = (try? persistentStorage.value(for: .tokenSearchQueryHistory)) ?? []
        let assets: [MarketsTokenModel] = (try? persistentStorage.value(for: .tokenSearchAssetHistory)) ?? []
        recentItemsSubject = CurrentValueSubject(Self.makeRecentItems(queries: queries, assets: assets))
    }

    // MARK: - Write

    func saveQuery(_ query: String) {
        var queries = loadQueries()
        insertRecent(query, into: &queries, matchedBy: { $0 == query })
        persist(queries, for: .tokenSearchQueryHistory)
        recentItemsSubject.send(Self.makeRecentItems(queries: queries, assets: loadAssets()))
    }

    func saveMarketAsset(_ tokenModel: MarketsTokenModel) {
        var assets = loadAssets()
        insertRecent(tokenModel, into: &assets, matchedBy: { $0.id == tokenModel.id })
        persist(assets, for: .tokenSearchAssetHistory)
        recentItemsSubject.send(Self.makeRecentItems(queries: loadQueries(), assets: assets))
    }

    func clearAll() {
        persist([String](), for: .tokenSearchQueryHistory)
        persist([MarketsTokenModel](), for: .tokenSearchAssetHistory)
        recentItemsSubject.send([])
    }

    // MARK: - Private

    private func loadQueries() -> [String] {
        (try? persistentStorage.value(for: .tokenSearchQueryHistory)) ?? []
    }

    private func loadAssets() -> [MarketsTokenModel] {
        (try? persistentStorage.value(for: .tokenSearchAssetHistory)) ?? []
    }

    private func insertRecent<T>(_ element: T, into list: inout [T], matchedBy isDuplicate: (T) -> Bool) {
        list.removeAll(where: isDuplicate)
        list.insert(element, at: 0)
        if list.count > maxItems {
            list.removeLast(list.count - maxItems)
        }
    }

    private static func makeRecentItems(queries: [String], assets: [MarketsTokenModel]) -> [MarketsTokenSearchRecentItem] {
        let queryItems = queries.map { MarketsTokenSearchRecentItem.query($0) }
        let assetItems = assets.map { MarketsTokenSearchRecentItem.marketAsset($0) }
        return queryItems + assetItems
    }

    private func persist<T: Encodable>(_ value: T, for key: PersistentStorageKey) {
        do {
            try persistentStorage.store(value: value, for: key)
        } catch {
            AppLogger.error(error: error)
        }
    }
}
