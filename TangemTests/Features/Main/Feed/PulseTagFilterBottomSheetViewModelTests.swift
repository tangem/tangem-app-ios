//
//  PulseTagFilterBottomSheetViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import Tangem

@Suite("PulseTagFilterBottomSheetViewModel", .tags(.marketsCategories))
@MainActor
struct PulseTagFilterBottomSheetViewModelTests {
    @Test("Loads the snapshot, splits out the featured tags and keeps the backend order")
    func loadsAndSplitsFeatured() async {
        let viewModel = makeViewModel(result: .success(snapshot(country: "US")))

        viewModel.onViewAppear()
        await viewModel.waitUntilLoaded()

        #expect(viewModel.loadingState == .loaded)
        #expect(viewModel.categoryItems.map(\.id) == MarketsGeckoCategoriesFixture.all.map(\.id))
        #expect(viewModel.featuredItems.map(\.id) == ["smart-contract-platform", "layer-1", "decentralized-identifier-did"])
        #expect(viewModel.categoryItems.first?.tokensCount == 548)
        #expect(viewModel.categoryItems.first?.marketCap.isEmpty == false)
    }

    @Test("Search narrows both lists by name, case-insensitively, and reports no results")
    func searchFiltersBothLists() async {
        let viewModel = makeViewModel(result: .success(snapshot(country: "US")))
        viewModel.onViewAppear()
        await viewModel.waitUntilLoaded()

        viewModel.searchText = "  layer "
        #expect(viewModel.categoryItems.map(\.id) == ["layer-1"])
        #expect(viewModel.featuredItems.map(\.id) == ["layer-1"])
        #expect(!viewModel.showsNoResults)

        viewModel.searchText = "bitcoin"
        #expect(viewModel.categoryItems.map(\.id) == ["bitcoin-ecosystem"])
        #expect(viewModel.featuredItems.isEmpty)

        viewModel.searchText = "nothing-like-this"
        #expect(viewModel.categoryItems.isEmpty)
        #expect(viewModel.showsNoResults)

        viewModel.searchText = ""
        #expect(viewModel.categoryItems.count == MarketsGeckoCategoriesFixture.all.count)
    }

    @Test("Starts from the current selection, Reset clears it and Apply hands back the tag with the country")
    func selectionResetAndApply() async {
        let applied = OSAllocatedUnfairLock(initialState: [PulseTagSelection?]())
        let dismissCount = OSAllocatedUnfairLock(initialState: 0)
        let viewModel = makeViewModel(
            result: .success(snapshot(country: "US")),
            selectedTagID: "layer-1",
            onApply: { selection in applied.withLock { $0.append(selection) } },
            onDismiss: { dismissCount.withLock { $0 += 1 } }
        )
        viewModel.onViewAppear()
        await viewModel.waitUntilLoaded()

        let layer1 = viewModel.categoryItems.first { $0.id == "layer-1" }!
        let did = viewModel.categoryItems.first { $0.id == "decentralized-identifier-did" }!

        #expect(viewModel.isSelected(layer1))

        viewModel.select(did)
        #expect(viewModel.isSelected(did))
        #expect(!viewModel.isSelected(layer1))

        viewModel.apply()
        #expect(applied.withLock { $0 } == [PulseTagSelection(id: "decentralized-identifier-did", name: "DID", country: "US")])
        #expect(dismissCount.withLock { $0 } == 1)

        viewModel.reset()
        #expect(viewModel.selectedTagID == nil)

        viewModel.apply()
        #expect(applied.withLock { $0.last } == .some(nil))
        #expect(dismissCount.withLock { $0 } == 2)
    }

    @Test("Apply with a selection the loaded list cannot resolve keeps the current tag and only dismisses")
    func applyWithUnresolvableSelectionKeepsTag() async {
        let applied = OSAllocatedUnfairLock(initialState: [PulseTagSelection?]())
        let dismissCount = OSAllocatedUnfairLock(initialState: 0)
        let viewModel = makeViewModel(
            result: .failure(MarketsCategoriesTestError.network),
            selectedTagID: "layer-1",
            onApply: { selection in applied.withLock { $0.append(selection) } },
            onDismiss: { dismissCount.withLock { $0 += 1 } }
        )
        viewModel.onViewAppear()
        await viewModel.waitUntilLoaded()

        #expect(viewModel.loadingState == .failed)

        viewModel.apply()
        #expect(applied.withLock { $0.isEmpty })
        #expect(dismissCount.withLock { $0 } == 1)

        viewModel.reset()
        viewModel.apply()
        #expect(applied.withLock { $0 } == [nil])
    }

    @Test("Closing the sheet mid-load cancels the request and leaves the state untouched")
    func closeCancelsLoad() async throws {
        let gate = OSAllocatedUnfairLock(initialState: false)
        let provider = StubGeckoCategoriesProvider(delay: .milliseconds(200)) {
            gate.withLock { $0 = true }
            return .success(snapshot(country: "US"))
        }
        let viewModel = makeViewModel(provider: provider)

        viewModel.onViewAppear()
        viewModel.close()

        try await Task.sleep(for: .milliseconds(400))

        #expect(viewModel.loadingState == .loading)
        #expect(viewModel.categoryItems.isEmpty)
        #expect(!gate.withLock { $0 })
    }

    @Test("An empty category list counts as a failure, and retry loads again")
    func emptyListFailsAndRetryReloads() async {
        let calls = OSAllocatedUnfairLock(initialState: 0)
        let provider = StubGeckoCategoriesProvider {
            let call = calls.withLock { $0 += 1; return $0 }
            return call == 1 ? .success(MarketsGeckoCategoriesSnapshot(categories: [], country: nil)) : .success(snapshot(country: nil))
        }
        let viewModel = makeViewModel(provider: provider)

        viewModel.onViewAppear()
        await viewModel.waitUntilLoaded()
        #expect(viewModel.loadingState == .failed)

        viewModel.retry()
        await viewModel.waitUntilLoaded()
        #expect(viewModel.loadingState == .loaded)
        #expect(calls.withLock { $0 } == 2)

        viewModel.onViewAppear()
        #expect(calls.withLock { $0 } == 2)
    }

    // MARK: - Helpers

    private func makeViewModel(
        result: Result<MarketsGeckoCategoriesSnapshot, Error>,
        selectedTagID: String? = nil,
        onApply: @escaping (PulseTagSelection?) -> Void = { _ in },
        onDismiss: @escaping () -> Void = {}
    ) -> PulseTagFilterBottomSheetViewModel {
        makeViewModel(
            provider: StubGeckoCategoriesProvider { result },
            selectedTagID: selectedTagID,
            onApply: onApply,
            onDismiss: onDismiss
        )
    }

    private func makeViewModel(
        provider: StubGeckoCategoriesProvider,
        selectedTagID: String? = nil,
        onApply: @escaping (PulseTagSelection?) -> Void = { _ in },
        onDismiss: @escaping () -> Void = {}
    ) -> PulseTagFilterBottomSheetViewModel {
        PulseTagFilterBottomSheetViewModel(
            input: PulseTagFilterInput(selectedTagID: selectedTagID, onApply: onApply),
            categoriesProvider: provider,
            marketCapFormatter: MarketCapFormatter(
                divisorsList: AmountNotationSuffixFormatter.Divisor.defaultList,
                baseCurrencyCode: "USD",
                notationFormatter: DefaultAmountNotationFormatter()
            ),
            onDismiss: onDismiss
        )
    }
}

private func snapshot(country: String?) -> MarketsGeckoCategoriesSnapshot {
    MarketsGeckoCategoriesSnapshot(categories: MarketsGeckoCategoriesFixture.all, country: country)
}

private struct StubGeckoCategoriesProvider: MarketsGeckoCategoriesProvider {
    var delay: Duration = .zero
    let result: @Sendable () -> Result<MarketsGeckoCategoriesSnapshot, Error>

    func categories() async throws -> MarketsGeckoCategoriesSnapshot {
        if delay > .zero {
            try await Task.sleep(for: delay)
        }

        return try result().get()
    }
}

private extension PulseTagFilterBottomSheetViewModel {
    func waitUntilLoaded(timeout: Duration = .seconds(5)) async {
        let deadline = ContinuousClock.now + timeout

        while await MainActor.run(body: { loadingState }) == .loading, ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(5))
        }
    }
}
