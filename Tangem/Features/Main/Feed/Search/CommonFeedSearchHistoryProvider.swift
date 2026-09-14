//
//  CommonFeedSearchHistoryProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

final class CommonFeedSearchHistoryProvider: FeedSearchHistoryProvider {
    var historyPublisher: AnyPublisher<FeedSearchHistory, Never> {
        historySubject.removeDuplicates().eraseToAnyPublisher()
    }

    private let storage: FeedSearchHistoryStorage
    private let historySubject = CurrentValueSubject<FeedSearchHistory, Never>(.empty)
    private let persistSubject = PassthroughSubject<StoredFeedSearchHistory, Never>()
    private let iconURLBuilder = IconURLBuilder()

    private var storedHistory: StoredFeedSearchHistory = .empty
    private var bag = Set<AnyCancellable>()

    init(storage: FeedSearchHistoryStorage) {
        self.storage = storage

        bind()
        loadStoredHistory()
    }

    func save(query: String) {
        let query = query.trimmed()

        guard query.isNotEmpty else {
            return
        }

        update { history in
            Self.prepend(query, to: &history.queries, capacity: Constants.queriesCapacity, replacing: { $0 == query })
        }
    }

    func save(token: MarketsTokenModel) {
        update { history in
            Self.prepend(token, to: &history.tokens, capacity: Constants.tokensCapacity, replacing: { $0.id == token.id })
        }
    }

    func remove(_ query: FeedRecentQuery) {
        update { history in
            history.queries.removeAll { $0 == query.value }
        }
    }

    func clear() {
        update { history in
            history = .empty
        }
    }
}

// MARK: - Private

private extension CommonFeedSearchHistoryProvider {
    func bind() {
        persistSubject
            .debounce(for: Constants.persistDebounce, scheduler: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { provider, history in
                provider.storage.save(history)
            }
            .store(in: &bag)
    }

    func loadStoredHistory() {
        guard var stored = storage.load() else {
            return
        }

        let needsTrimming = stored.queries.count > Constants.queriesCapacity || stored.tokens.count > Constants.tokensCapacity
        stored.queries = Array(stored.queries.prefix(Constants.queriesCapacity))
        stored.tokens = Array(stored.tokens.prefix(Constants.tokensCapacity))
        if needsTrimming { persistSubject.send(stored) }
        storedHistory = stored
        historySubject.send(makeHistory(from: stored))
    }

    func update(_ change: (inout StoredFeedSearchHistory) -> Void) {
        change(&storedHistory)
        historySubject.send(makeHistory(from: storedHistory))
        persistSubject.send(storedHistory)
    }

    func makeHistory(from stored: StoredFeedSearchHistory) -> FeedSearchHistory {
        FeedSearchHistory(
            tokens: stored.tokens.map { token in
                FeedRecentToken(
                    id: token.id,
                    caption: token.name,
                    icon: .remote(name: token.name, imageURL: iconURLBuilder.tokenIconURL(id: token.id)),
                    model: token
                )
            },
            queries: stored.queries.map(FeedRecentQuery.init)
        )
    }

    static func prepend<T>(_ element: T, to list: inout [T], capacity: Int, replacing isSame: (T) -> Bool) {
        list.removeAll(where: isSame)
        list.insert(element, at: 0)
        list = Array(list.prefix(capacity))
    }
}

// MARK: - Constants

private extension CommonFeedSearchHistoryProvider {
    enum Constants {
        static let tokensCapacity = 10
        static let queriesCapacity = 5
        static let persistDebounce: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(500)
    }
}
