//
//  RealAssetsSearchViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemTestKit
import Testing
@testable import Tangem

@Suite("RealAssetsSearchViewModel", .serialized)
@MainActor
final class RealAssetsSearchViewModelTests: LeakTrackingTestSuite {
    typealias SUT = RealAssetsSearchViewModel

    private let query = CurrentValueSubject<String, Never>("")

    @Test("A fruitless query settles on the empty state")
    func fruitlessQuerySettlesOnEmptyState() async throws {
        let provider = SearchProviderStub()
        let sut = makeSUT(assetsProvider: provider)
        sut.setVisible(true)

        query.send("zzz")

        #expect(try await waitForState(of: sut, matching: \.isEmpty))
        #expect(provider.queries == ["zzz"])
    }

    @Test("A query typed while the tab is off screen is asked for once the tab is shown")
    func queryTypedOffScreenIsAskedWhenShown() async throws {
        let provider = SearchProviderStub()
        let sut = makeSUT(assetsProvider: provider)

        query.send("zzz")

        try await Task.sleep(nanoseconds: Constants.debounceWait)
        #expect(provider.queries.isEmpty)

        sut.setVisible(true)

        #expect(try await waitForState(of: sut, matching: \.isEmpty))
        #expect(provider.queries == ["zzz"])
    }

    @Test("Retyping the same fruitless query searches again instead of leaving a skeleton")
    func retypedFruitlessQuerySearchesAgain() async throws {
        let provider = SearchProviderStub()
        let sut = makeSUT(assetsProvider: provider)
        sut.setVisible(true)

        query.send("zzz")
        #expect(try await waitForState(of: sut, matching: \.isEmpty))

        query.send("zzzq")
        query.send("zzz")

        #expect(try await waitForState(of: sut, matching: \.isLoading))
        #expect(try await waitForState(of: sut, matching: \.isEmpty))
        #expect(provider.queries == ["zzz", "zzz"])
    }

    @Test("A cleared query drops the results and the provider's state with them")
    func clearedQueryResetsTheProvider() async throws {
        let provider = SearchProviderStub()
        let sut = makeSUT(assetsProvider: provider)
        sut.setVisible(true)

        query.send("zzz")
        #expect(try await waitForState(of: sut, matching: \.isEmpty))

        query.send("")

        #expect(try await waitForState(of: sut, matching: \.isLoading))
        #expect(provider.didReset)
    }
}

// MARK: - Helpers

private extension RealAssetsSearchViewModelTests {
    func makeSUT(assetsProvider: some FeedSearchProvider<MarketsTokenModel>) -> SUT {
        let sut = SUT(
            query: query.eraseToAnyPublisher(),
            router: RouterStub(),
            portfolioProvider: FeedSearchPortfolioProvider(query: query.eraseToAnyPublisher(), onSelect: { _ in }),
            assetsProvider: assetsProvider
        )

        return trackForMemoryLeaks(sut)
    }

    func waitForState(
        of sut: SUT,
        matching keyPath: KeyPath<SUT.AssetsState, Bool>
    ) async throws -> Bool {
        for _ in 0 ..< Constants.pollAttempts {
            try await Task.sleep(nanoseconds: Constants.pollInterval)

            if sut.assets[keyPath: keyPath] {
                return true
            }
        }

        return false
    }
}

// MARK: - State matchers

private extension RealAssetsSearchViewModel.AssetsState {
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var isEmpty: Bool {
        if case .empty = self { return true }
        return false
    }
}

// MARK: - Stubs

private final class SearchProviderStub: FeedSearchProvider {
    typealias Item = MarketsTokenModel

    var statePublisher: AnyPublisher<FeedSearchProviderState<MarketsTokenModel>, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    private(set) var queries: [String] = []
    private(set) var didReset = false

    private let stateSubject = CurrentValueSubject<FeedSearchProviderState<MarketsTokenModel>, Never>(.loading)

    func search(_ query: String) {
        queries.append(query)
        stateSubject.send(.empty)
    }

    func reset() {
        didReset = true
        stateSubject.send(.loading)
    }
}

private final class RouterStub: RealAssetsFeedRoutable {
    func openToken(_ token: MarketsTokenModel) {}
    func openCategoryFilter(with input: RealAssetsCategoryFilterInput) {}
}

// MARK: - Constants

private extension RealAssetsSearchViewModelTests {
    enum Constants {
        static let pollAttempts = 60
        static let pollInterval: UInt64 = 50 * NSEC_PER_MSEC
        static let debounceWait: UInt64 = 700 * NSEC_PER_MSEC
    }
}
