//
//  EarnSearchViewModelTests.swift
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

@Suite("EarnSearchViewModel", .serialized)
@MainActor
final class EarnSearchViewModelTests: LeakTrackingTestSuite {
    typealias SUT = EarnSearchViewModel

    private let query = CurrentValueSubject<String, Never>("")

    @Test("A fruitless query settles on the empty state")
    func fruitlessQuerySettlesOnEmptyState() async throws {
        let provider = SearchProviderStub()
        let sut = makeSUT(searchProvider: provider)
        sut.setVisible(true)

        query.send("zzz")

        #expect(try await waitForState(of: sut, matching: \.isEmpty))
        #expect(provider.queries == ["zzz"])
    }

    @Test("Retyping the same fruitless query searches again instead of leaving a skeleton")
    func retypedFruitlessQuerySearchesAgain() async throws {
        let provider = SearchProviderStub()
        let sut = makeSUT(searchProvider: provider)
        sut.setVisible(true)

        query.send("zzz")
        #expect(try await waitForState(of: sut, matching: \.isEmpty))

        query.send("zzzq")
        query.send("zzz")

        #expect(try await waitForState(of: sut, matching: \.isLoading))
        #expect(try await waitForState(of: sut, matching: \.isEmpty))
        #expect(provider.queries == ["zzz", "zzz"])
    }
}

// MARK: - Helpers

private extension EarnSearchViewModelTests {
    func makeSUT(searchProvider: some FeedSearchProvider<EarnTokenModel>) -> SUT {
        let sut = SUT(
            query: query.eraseToAnyPublisher(),
            history: HistoryProviderStub(),
            router: RouterStub(),
            searchProvider: searchProvider
        )

        return trackForMemoryLeaks(sut)
    }

    func waitForState(
        of sut: SUT,
        matching keyPath: KeyPath<SUT.OpportunitiesState, Bool>
    ) async throws -> Bool {
        for _ in 0 ..< Constants.pollAttempts {
            try await Task.sleep(nanoseconds: Constants.pollInterval)

            if sut.opportunities[keyPath: keyPath] {
                return true
            }
        }

        return false
    }
}

// MARK: - State matchers

private extension EarnSearchViewModel.OpportunitiesState {
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
    typealias Item = EarnTokenModel

    var statePublisher: AnyPublisher<FeedSearchProviderState<EarnTokenModel>, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    private(set) var queries: [String] = []

    private let stateSubject = CurrentValueSubject<FeedSearchProviderState<EarnTokenModel>, Never>(.loading)

    func search(_ query: String) {
        queries.append(query)
        stateSubject.send(.empty)
    }

    func reset() {
        stateSubject.send(.loading)
    }
}

private final class HistoryProviderStub: FeedSearchHistoryProvider {
    var historyPublisher: AnyPublisher<FeedSearchHistory, Never> {
        Empty<FeedSearchHistory, Never>(completeImmediately: false).eraseToAnyPublisher()
    }

    func save(query: String) {}
    func remove(_ query: FeedRecentQuery) {}
    func clear() {}
}

private final class RouterStub: EarnFeedRoutable {
    func routeOnTokenResolved(_ resolution: EarnTokenResolution, source: EarnOpportunitySource) {}
    func openPortfolioToken(_ walletModel: any WalletModel) {}
    func openNetworksFilter() {}
    func openTypesFilter() {}
}

// MARK: - Constants

private extension EarnSearchViewModelTests {
    enum Constants {
        static let pollAttempts = 60
        static let pollInterval: UInt64 = 50 * NSEC_PER_MSEC
    }
}
