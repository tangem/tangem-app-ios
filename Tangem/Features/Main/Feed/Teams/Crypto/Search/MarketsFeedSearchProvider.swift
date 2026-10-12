//
//  MarketsFeedSearchProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

final class MarketsFeedSearchProvider: FeedSearchProvider {
    var statePublisher: AnyPublisher<FeedSearchProviderState<MarketsTokenModel>, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    private let stateSubject = CurrentValueSubject<FeedSearchProviderState<MarketsTokenModel>, Never>(.loading)
    private let listProvider = MarketsListDataProvider()
    private let filter = MarketsListDataProvider.Filter(interval: .day, order: .rating)
    private var bag = Set<AnyCancellable>()

    init() {
        bind()
    }

    func search(_ query: String) {
        listProvider.reset()
        listProvider.fetch(query, with: filter)
    }

    func loadMore() {
        guard listProvider.canFetchMore else {
            return
        }

        listProvider.fetchMore()
    }

    func reset() {
        listProvider.reset()
    }

    private func bind() {
        listProvider
            .$lastEvent
            .withWeakCaptureOf(self)
            .compactMap { provider, event -> FeedSearchProviderState<MarketsTokenModel>? in
                let items = provider.listProvider.items

                switch event {
                case .loading, .startInitialFetch, .cleared:
                    return .loading
                case .appendedItems:
                    return items.isEmpty ? .empty : .loaded(items)
                case .failedToFetchData:
                    return items.isEmpty ? .failed : nil
                case .idle:
                    return nil
                }
            }
            .withWeakCaptureOf(self)
            .sink { provider, state in
                provider.stateSubject.send(state)
            }
            .store(in: &bag)
    }
}
