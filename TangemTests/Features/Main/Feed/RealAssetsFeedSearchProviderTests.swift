//
//  RealAssetsFeedSearchProviderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import Testing
@testable import Tangem

@Suite("RealAssetsFeedSearchProvider", .serialized)
@MainActor
struct RealAssetsFeedSearchProviderTests {
    @Test("The market is asked for the umbrella category, in the country the categories were resolved for")
    func scopesTheMarketToTheUmbrella() {
        let snapshot = Self.snapshot(categories: [Self.commodities, Self.umbrella])

        let filter = RealAssetsFeedSearchProvider.makeFilter(from: snapshot)

        #expect(filter?.categoryId == Self.umbrella.id)
        #expect(filter?.country == snapshot.country)
        #expect(filter?.sectorId == nil)
        #expect(filter?.geckoCategoryId == nil)
        #expect(filter?.interval == .day)
        #expect(filter?.order == .rating)
    }

    @Test("Categories that don't carry the umbrella leave the query unanswered rather than searching the whole market")
    func failsWithoutTheUmbrellaCategory() async {
        let categories = CategoriesProviderStub(result: .success(Self.snapshot(categories: [Self.commodities])))
        let provider = RealAssetsFeedSearchProvider(categoriesProvider: categories)
        let states = StateRecorder(provider: provider)

        provider.search("gold")

        #expect(await states.waitForFailure())
        withExtendedLifetime(provider) {}
    }

    @Test("A failed categories request is what the tab reports, not an empty result")
    func failsWhenCategoriesFail() async {
        let categories = CategoriesProviderStub(result: .failure(CategoriesError.offline))
        let provider = RealAssetsFeedSearchProvider(categoriesProvider: categories)
        let states = StateRecorder(provider: provider)

        provider.search("gold")

        #expect(await states.waitForFailure())
        withExtendedLifetime(provider) {}
    }

    @Test("Typing while the scope is still loading asks for the categories once")
    func loadsCategoriesOnce() async {
        let categories = CategoriesProviderStub(result: .failure(CategoriesError.offline), delay: .milliseconds(200))
        let provider = RealAssetsFeedSearchProvider(categoriesProvider: categories)

        provider.search("go")
        provider.search("gol")
        provider.search("gold")

        try? await Task.sleep(for: .milliseconds(400))

        #expect(categories.requestCount == 1)
        withExtendedLifetime(provider) {}
    }
}

// MARK: - Fixtures

private extension RealAssetsFeedSearchProviderTests {
    static let commodities = MarketsDTO.Categories.Category(
        id: 1,
        code: MarketsCategoryCode.commodities,
        displayName: "Commodities",
        displayOrder: 1,
        restricted: false,
        tokensCount: 10,
        sectors: [],
        visible: true
    )

    static let umbrella = MarketsDTO.Categories.Category(
        id: 7,
        code: MarketsCategoryCode.realWorldAssets,
        displayName: "Real world assets",
        displayOrder: 0,
        restricted: false,
        tokensCount: 42,
        sectors: [],
        visible: true
    )

    static func snapshot(categories: [MarketsDTO.Categories.Category]) -> MarketsCategoriesSnapshot {
        MarketsCategoriesSnapshot(categories: categories, country: "US")
    }
}

// MARK: - State recorder

@MainActor
private final class StateRecorder {
    private var isFailed = false
    private var bag = Set<AnyCancellable>()

    init(provider: some FeedSearchProvider<MarketsTokenModel>) {
        provider
            .statePublisher
            .sink { [weak self] state in
                if case .failed = state {
                    self?.isFailed = true
                }
            }
            .store(in: &bag)
    }

    func waitForFailure() async -> Bool {
        for _ in 0 ..< Constants.pollAttempts {
            if isFailed {
                return true
            }

            try? await Task.sleep(for: Constants.pollInterval)
        }

        return isFailed
    }

    private enum Constants {
        static let pollAttempts = 40
        static let pollInterval: Duration = .milliseconds(50)
    }
}

// MARK: - Stubs

private final class CategoriesProviderStub: MarketsCategoriesProvider, @unchecked Sendable {
    var requestCount: Int { requests.withLock { $0 } }

    private let requests = OSAllocatedUnfairLock(initialState: 0)
    private let result: Result<MarketsCategoriesSnapshot, Error>
    private let delay: Duration

    init(result: Result<MarketsCategoriesSnapshot, Error>, delay: Duration = .zero) {
        self.result = result
        self.delay = delay
    }

    func categories() async throws -> MarketsCategoriesSnapshot {
        requests.withLock { $0 += 1 }

        if delay > .zero {
            try await Task.sleep(for: delay)
        }

        return try result.get()
    }
}

private enum CategoriesError: Error {
    case offline
}
