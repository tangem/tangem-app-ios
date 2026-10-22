//
//  EarnFeedSearchProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

final class EarnFeedSearchProvider: FeedSearchProvider {
    var statePublisher: AnyPublisher<FeedSearchProviderState<EarnTokenModel>, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private let stateSubject = CurrentValueSubject<FeedSearchProviderState<EarnTokenModel>, Never>(.loading)
    private let makeEthereumP2PFilter: () -> EarnEthereumP2PFilter
    private let matcher = EarnSearchMatcher()
    private let mapper = EarnModelMapper()

    private var catalog: [EarnTokenModel]?
    private var query = ""
    private var isLoadingCatalog = false
    private var catalogTask: AnyCancellable?

    init(ethereumP2PFilter: @escaping () -> EarnEthereumP2PFilter = { CommonEarnEthereumP2PFilter() }) {
        makeEthereumP2PFilter = ethereumP2PFilter
    }

    deinit {
        catalogTask?.cancel()
    }

    func search(_ query: String) {
        self.query = query

        guard let catalog else {
            stateSubject.send(.loading)
            loadCatalog()
            return
        }

        send(matches: matcher.match(catalog, query: query))
    }

    func reset() {
        query = ""
        stateSubject.send(.loading)
    }
}

// MARK: - Catalogue

private extension EarnFeedSearchProvider {
    func loadCatalog() {
        guard !isLoadingCatalog else {
            return
        }

        isLoadingCatalog = true
        catalogTask = runTask(in: self) { provider in
            do {
                let catalog = try await provider.loadCatalogPages()
                await provider.apply(catalog: catalog)
            } catch {
                if error.isCancellationError {
                    return
                }

                AppLogger.tag("Earn").error("Failed to load the search catalogue", error: error)
                await provider.applyCatalogFailure()
            }
        }.eraseToAnyCancellable()
    }

    func loadCatalogPages() async throws -> [EarnTokenModel] {
        var items: [EarnDTO.List.Item] = []
        var page = Constants.firstPage

        while true {
            let request = EarnDTO.List.Request(
                isForEarn: false,
                page: page,
                limit: Constants.pageSize,
                type: nil,
                networkIds: nil,
                apyType: FeatureProvider.isAvailable(.merklIncentives) ? .gross : nil
            )

            let response = try await tangemApiService.loadEarnYieldMarkets(requestModel: request)
            items += response.items

            guard response.meta.hasNext, response.items.isNotEmpty else {
                break
            }

            guard page < Constants.maxPageCount else {
                throw CatalogueError.tooManyPages
            }

            page += 1
        }

        let filtered = try await makeEthereumP2PFilter().filter(items)

        return makeTokens(from: filtered)
    }

    func makeTokens(from items: [EarnDTO.List.Item]) -> [EarnTokenModel] {
        items
            .map(mapper.mapToEarnTokenModel(from:))
            .unique(by: \.opportunityKey)
    }

    @MainActor
    func apply(catalog: [EarnTokenModel]) {
        isLoadingCatalog = false
        self.catalog = catalog

        send(matches: matcher.match(catalog, query: query))
    }

    @MainActor
    func applyCatalogFailure() {
        isLoadingCatalog = false
        stateSubject.send(.failed)
    }

    func send(matches: [EarnTokenModel]) {
        stateSubject.send(matches.isEmpty ? .empty : .loaded(matches))
    }
}

// MARK: - Opportunity key

private extension EarnTokenModel {
    struct OpportunityKey: Hashable {
        let id: String
        let networkId: String
        let earnType: EarnType
    }

    var opportunityKey: OpportunityKey {
        OpportunityKey(id: id, networkId: networkId, earnType: earnType)
    }
}

// MARK: - Error

private extension EarnFeedSearchProvider {
    enum CatalogueError: Error {
        case tooManyPages
    }
}

// MARK: - Constants

private extension EarnFeedSearchProvider {
    enum Constants {
        static let firstPage = 1
        static let pageSize = 100
        static let maxPageCount = 50
    }
}
