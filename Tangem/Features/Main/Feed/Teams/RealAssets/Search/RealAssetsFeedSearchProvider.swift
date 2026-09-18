//
//  RealAssetsFeedSearchProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

final class RealAssetsFeedSearchProvider: FeedSearchProvider {
    var statePublisher: AnyPublisher<FeedSearchProviderState<MarketsTokenModel>, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    private let categoriesProvider: MarketsCategoriesProvider
    private let stateSubject = CurrentValueSubject<FeedSearchProviderState<MarketsTokenModel>, Never>(.loading)
    private let listProvider = MarketsListDataProvider()

    private var filter: MarketsListDataProvider.Filter?
    private var pendingQuery: String?
    private var isLoadingCategories = false
    private var categoriesTask: Task<Void, Never>?
    private var bag = Set<AnyCancellable>()

    init(categoriesProvider: MarketsCategoriesProvider = InjectedValues[\.marketsCategoriesProvider]) {
        self.categoriesProvider = categoriesProvider

        bind()
    }

    deinit {
        categoriesTask?.cancel()
    }

    func search(_ query: String) {
        guard let filter else {
            pendingQuery = query
            stateSubject.send(.loading)
            loadCategories()
            return
        }

        fetch(query, with: filter)
    }

    func loadMore() {
        guard listProvider.canFetchMore else {
            return
        }

        listProvider.fetchMore()
    }

    func reset() {
        pendingQuery = nil
        listProvider.reset()
    }
}

// MARK: - The real assets scope

private extension RealAssetsFeedSearchProvider {
    func loadCategories() {
        guard !isLoadingCategories else {
            return
        }

        isLoadingCategories = true

        let categoriesProvider = categoriesProvider

        categoriesTask = Task { @MainActor [weak self] in
            defer { self?.isLoadingCategories = false }

            do {
                let snapshot = try await categoriesProvider.categories()

                guard let self else { return }

                guard let filter = Self.makeFilter(from: snapshot) else {
                    throw RealAssetsSearchError.noUmbrellaCategory
                }

                apply(filter)
            } catch {
                guard let self, !error.isCancellationError else { return }

                AppLogger.tag("Markets").error("Failed to load the real assets search scope", error: error)
                stateSubject.send(.failed)
            }
        }
    }

    func apply(_ filter: MarketsListDataProvider.Filter) {
        self.filter = filter

        guard let pendingQuery else {
            return
        }

        self.pendingQuery = nil
        fetch(pendingQuery, with: filter)
    }

    func fetch(_ query: String, with filter: MarketsListDataProvider.Filter) {
        listProvider.reset()
        listProvider.fetch(query, with: filter)
    }
}

// MARK: - Scope

extension RealAssetsFeedSearchProvider {
    static func makeFilter(from snapshot: MarketsCategoriesSnapshot) -> MarketsListDataProvider.Filter? {
        snapshot.umbrellaCategory.map { umbrella in
            MarketsListDataProvider.Filter(
                interval: Constants.interval,
                order: Constants.order,
                categoryId: umbrella.id,
                country: snapshot.country
            )
        }
    }
}

// MARK: - Results

private extension RealAssetsFeedSearchProvider {
    func bind() {
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

// MARK: - Error

private enum RealAssetsSearchError: Error {
    case noUmbrellaCategory
}

// MARK: - Constants

private extension RealAssetsFeedSearchProvider {
    enum Constants {
        static let interval: MarketsPriceIntervalType = .day
        static let order: MarketsListOrderType = .rating
    }
}
