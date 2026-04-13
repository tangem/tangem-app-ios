//
//  StubTokenSearchStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

actor StubTokenSearchStorage: TokenSearchStorage {
    nonisolated var recentItemsPublisher: AnyPublisher<[TokenSearchRecentItem], Never> {
        recentItemsSubject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private let maxItems = 3
    private var queries: [String] = []
    private var assets: [MarketsTokenModel] = []
    private nonisolated let recentItemsSubject = CurrentValueSubject<[TokenSearchRecentItem], Never>([])

    func saveQuery(_ query: String) {
        insertRecent(query, into: &queries, matchedBy: { $0 == query })
        recentItemsSubject.send(makeRecentItems())
    }

    func saveMarketAsset(_ tokenModel: MarketsTokenModel) {
        insertRecent(tokenModel, into: &assets, matchedBy: { $0.id == tokenModel.id })
        recentItemsSubject.send(makeRecentItems())
    }

    func clearAll() {
        queries.removeAll()
        assets.removeAll()
        recentItemsSubject.send([])
    }

    private func insertRecent<T>(_ element: T, into list: inout [T], matchedBy isDuplicate: (T) -> Bool) {
        list.removeAll(where: isDuplicate)
        list.insert(element, at: 0)
        if list.count > maxItems {
            list.removeLast(list.count - maxItems)
        }
    }

    private func makeRecentItems() -> [TokenSearchRecentItem] {
        let queryItems = queries.map { TokenSearchRecentItem.query($0) }
        let assetItems = assets.map { TokenSearchRecentItem.marketAsset($0) }
        return queryItems + assetItems
    }
}
