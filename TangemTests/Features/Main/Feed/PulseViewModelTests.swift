//
//  PulseViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
import TangemFoundation
import TangemLocalization
@testable import Tangem

@Suite("PulseViewModel", .tags(.marketsCategories))
@MainActor
struct PulseViewModelTests {
    @Test("Without a tag every sort is offered and the list loads untagged")
    func untaggedDefaults() {
        let dataProvider = StubPulseDataProvider()
        let viewModel = makeViewModel(dataProvider: dataProvider)

        viewModel.onViewAppear()

        #expect(viewModel.categories == PulseCategory.allCases)
        #expect(viewModel.selectedTag == nil)
        #expect(viewModel.tagChipTitle == Localization.marketCategories)
        #expect(dataProvider.loads.count == 1)
        #expect(dataProvider.loads.last?.tag == nil)
    }

    @Test("Applying a tag from the sheet narrows the sorts, drops an unsupported one and reloads with the tag")
    func applyingTagNarrowsSorts() {
        let dataProvider = StubPulseDataProvider()
        let router = StubCryptoFeedRoutable()
        let viewModel = makeViewModel(dataProvider: dataProvider, router: router)
        viewModel.onViewAppear()
        viewModel.onSelectCategory(.experiencedBuyers)

        viewModel.onTagChipTap()
        let input = router.tagFilterInputs.last
        #expect(input?.selectedTagID == nil)

        let selection = PulseTagSelection(id: "layer-1", name: "Layer 1 (L1)", country: "US")
        input?.onApply(selection)

        #expect(viewModel.selectedTag == selection)
        #expect(viewModel.tagChipTitle == "Layer 1 (L1)")
        #expect(viewModel.categories == PulseCategory.supportedWithTag)
        #expect(viewModel.selectedCategory == .marketCap)
        #expect(dataProvider.loads.last?.tag == selection)
        #expect(dataProvider.loads.last?.category == .marketCap)
        #expect(dataProvider.loads.last?.isCategoryUserInitiated == false)

        viewModel.onTagChipTap()
        #expect(router.tagFilterInputs.last?.selectedTagID == "layer-1")
    }

    @Test("A supported sort survives the tag, re-applying the same tag does not reload, and clearing brings every sort back")
    func supportedSortSurvivesAndClearRestores() {
        let dataProvider = StubPulseDataProvider()
        let router = StubCryptoFeedRoutable()
        let viewModel = makeViewModel(dataProvider: dataProvider, router: router)
        viewModel.onViewAppear()
        viewModel.onSelectCategory(.topGainers)
        dataProvider.loads.removeAll()

        let selection = PulseTagSelection(id: "decentralized-identifier-did", name: "DID", country: nil)
        viewModel.onTagChipTap()
        router.tagFilterInputs.last?.onApply(selection)

        #expect(viewModel.selectedCategory == .topGainers)
        #expect(dataProvider.loads.map(\.tag) == [selection])
        #expect(dataProvider.loads.last?.isCategoryUserInitiated == true)

        // The sheet refetches the categories every time it opens, so the market cap and the asset count behind
        // the tag have moved on — applying the same tag again must not reload the list.
        viewModel.onTagChipTap()
        router.tagFilterInputs.last?.onApply(selection)
        #expect(dataProvider.loads.count == 1)
        #expect(viewModel.tagChipTitle == "DID")

        viewModel.onTagClearTap()
        #expect(viewModel.selectedTag == nil)
        #expect(viewModel.categories == PulseCategory.allCases)
        #expect(viewModel.selectedCategory == .topGainers)
        #expect(dataProvider.loads.count == 2)
        #expect(dataProvider.loads.last?.tag == nil)
    }

    // MARK: - Requested category

    @Test("A requested category holds the list back until it resolves, then loads once with the tag")
    func requestedCategoryWaitsAndLoadsTagged() async {
        let dataProvider = StubPulseDataProvider()
        let viewModel = makeViewModel(dataProvider: dataProvider, result: .success(snapshot(country: "US")))

        viewModel.select(categoryId: "layer-1")
        viewModel.onViewAppear()
        #expect(dataProvider.loads.isEmpty)

        #expect(await wait(until: { !dataProvider.loads.isEmpty }))

        let expected = PulseTagSelection(id: "layer-1", name: "Layer 1 (L1)", country: "US")
        #expect(viewModel.selectedTag == expected)
        #expect(viewModel.tagChipTitle == "Layer 1 (L1)")
        #expect(dataProvider.loads.map(\.tag) == [expected])

        viewModel.onViewAppear()
        #expect(dataProvider.loads.count == 1)
    }

    @Test("A category the backend doesn't know leaves the list untagged")
    func unknownRequestedCategoryFallsBackToUntagged() async {
        let dataProvider = StubPulseDataProvider()
        let viewModel = makeViewModel(dataProvider: dataProvider, result: .success(snapshot(country: "US")))

        viewModel.select(categoryId: "no-such-category")
        #expect(await wait(until: { !dataProvider.loads.isEmpty }))

        #expect(viewModel.selectedTag == nil)
        #expect(viewModel.categories == PulseCategory.allCases)
        #expect(dataProvider.loads.map(\.tag) == [nil])
    }

    @Test("A resolution that fails leaves the list untagged rather than held back")
    func failedCategoryResolutionFallsBackToUntagged() async {
        let dataProvider = StubPulseDataProvider()
        let viewModel = makeViewModel(dataProvider: dataProvider, result: .failure(MarketsCategoriesTestError.network))

        viewModel.select(categoryId: "layer-1")
        #expect(await wait(until: { !dataProvider.loads.isEmpty }))

        #expect(viewModel.selectedTag == nil)
        #expect(dataProvider.loads.map(\.tag) == [nil])
    }

    @Test("A tag picked in the sheet while the requested category is still resolving is not overwritten by it")
    func sheetSelectionWinsOverAnUnresolvedCategory() async {
        let dataProvider = StubPulseDataProvider()
        let router = StubCryptoFeedRoutable()
        let isResolving = OSAllocatedUnfairLock(initialState: false)
        let viewModel = makeViewModel(
            dataProvider: dataProvider,
            router: router,
            result: .success(snapshot(country: "US")),
            delay: .milliseconds(200),
            onRequest: { isResolving.withLock { $0 = true } }
        )

        viewModel.select(categoryId: "layer-1")
        #expect(await wait(until: { isResolving.withLock { $0 } }))

        let selection = PulseTagSelection(id: "decentralized-identifier-did", name: "DID", country: "US")
        viewModel.onTagChipTap()
        router.tagFilterInputs.last?.onApply(selection)

        #expect(viewModel.selectedTag == selection)

        try? await Task.sleep(for: .milliseconds(400))

        #expect(viewModel.selectedTag == selection)
        #expect(dataProvider.loads.map(\.tag) == [selection])
    }

    @Test("Clearing the filter over an unresolved category still asks for the list it was holding back")
    func clearingTheFilterOverAnUnresolvedCategoryLoads() async {
        let dataProvider = StubPulseDataProvider()
        let router = StubCryptoFeedRoutable()
        let isResolving = OSAllocatedUnfairLock(initialState: false)
        let viewModel = makeViewModel(
            dataProvider: dataProvider,
            router: router,
            result: .success(snapshot(country: "US")),
            delay: .milliseconds(200),
            onRequest: { isResolving.withLock { $0 = true } }
        )

        viewModel.select(categoryId: "layer-1")
        #expect(await wait(until: { isResolving.withLock { $0 } }))

        viewModel.onViewAppear()
        #expect(dataProvider.loads.isEmpty)

        viewModel.onTagChipTap()
        router.tagFilterInputs.last?.onApply(nil)

        #expect(await wait(until: { dataProvider.loads.isNotEmpty }))
        #expect(dataProvider.loads.map(\.tag) == [nil])

        try? await Task.sleep(for: .milliseconds(400))

        #expect(dataProvider.loads.count == 1)
    }

    @Test("A tag picked on a list that failed asks for exactly one load")
    func tagSelectionOnFailedListLoadsOnce() async {
        let dataProvider = StubPulseDataProvider()
        let router = StubCryptoFeedRoutable()
        let viewModel = makeViewModel(dataProvider: dataProvider, router: router)

        viewModel.onViewAppear()
        dataProvider.failedSubject.send(true)
        #expect(await wait(until: { viewModel.isFailed }))

        dataProvider.loads.removeAll()

        let selection = PulseTagSelection(id: "layer-1", name: "Layer 1 (L1)", country: "US")
        viewModel.onTagChipTap()
        router.tagFilterInputs.last?.onApply(selection)

        #expect(dataProvider.loads.map(\.tag) == [selection])
    }

    @Test("A requested category resolving onto a list that failed asks for exactly one load")
    func requestedCategoryResolutionOnFailedListLoadsOnce() async {
        let dataProvider = StubPulseDataProvider()
        let viewModel = makeViewModel(dataProvider: dataProvider, result: .success(snapshot(country: "US")))

        viewModel.onViewAppear()
        dataProvider.failedSubject.send(true)
        #expect(await wait(until: { viewModel.isFailed }))

        dataProvider.loads.removeAll()

        viewModel.select(categoryId: "layer-1")
        #expect(await wait(until: { !dataProvider.loads.isEmpty }))

        #expect(dataProvider.loads.map(\.tag) == [PulseTagSelection(id: "layer-1", name: "Layer 1 (L1)", country: "US")])
    }

    @Test("Retrying a failed list while its category is still resolving does not reload on the filter it is leaving")
    func retryWaitsForTheRequestedCategory() async {
        let dataProvider = StubPulseDataProvider()
        let isResolving = OSAllocatedUnfairLock(initialState: false)
        let viewModel = makeViewModel(
            dataProvider: dataProvider,
            result: .success(snapshot(country: "US")),
            delay: .milliseconds(200),
            onRequest: { isResolving.withLock { $0 = true } }
        )

        viewModel.onViewAppear()
        dataProvider.failedSubject.send(true)
        #expect(await wait(until: { viewModel.isFailed }))

        dataProvider.loads.removeAll()

        viewModel.select(categoryId: "layer-1")
        #expect(await wait(until: { isResolving.withLock { $0 } }))

        viewModel.onRetry()
        #expect(dataProvider.loads.isEmpty)

        #expect(await wait(until: { dataProvider.loads.isNotEmpty }))
        #expect(dataProvider.loads.map(\.tag) == [PulseTagSelection(id: "layer-1", name: "Layer 1 (L1)", country: "US")])
    }

    @Test("A superseded resolution failing on its own leaves the category asked for after it alone")
    func failedSupersededResolutionLeavesTheNewerOneAlone() async {
        let dataProvider = StubPulseDataProvider()
        let requests = OSAllocatedUnfairLock(initialState: 0)
        let viewModel = makeViewModel(
            dataProvider: dataProvider,
            ignoresCancellation: true,
            onRequest: { requests.withLock { $0 += 1 } },
            // The superseded request is still out when the newer one is asked for, and answers with a failure
            // of its own once dropped.
            delayForRequest: { index in index == 0 ? .seconds(10) : .zero },
            resultForRequest: { index in
                index == 0 ? .failure(MarketsCategoriesTestError.network) : .success(snapshot(country: "US"))
            }
        )

        viewModel.select(categoryId: "decentralized-identifier-did")
        #expect(await wait(until: { requests.withLock { $0 } == 1 }))

        viewModel.select(categoryId: "layer-1")
        #expect(await wait(until: { dataProvider.loads.isNotEmpty }))

        try? await Task.sleep(for: .milliseconds(200))

        #expect(viewModel.selectedTag == PulseTagSelection(id: "layer-1", name: "Layer 1 (L1)", country: "US"))
        #expect(dataProvider.loads.map(\.tag) == [PulseTagSelection(id: "layer-1", name: "Layer 1 (L1)", country: "US")])
    }

    @Test("A resolution landing on the tag already shown still asks for the list its retry was refused")
    func resolutionOntoTheSameTagLoadsTheFailedList() async {
        let dataProvider = StubPulseDataProvider()
        let isResolving = OSAllocatedUnfairLock(initialState: false)
        let viewModel = makeViewModel(
            dataProvider: dataProvider,
            result: .success(snapshot(country: "US")),
            delay: .milliseconds(200),
            onRequest: { isResolving.withLock { $0 = true } }
        )

        viewModel.select(categoryId: "layer-1")
        #expect(await wait(until: { dataProvider.loads.isNotEmpty }))

        dataProvider.failedSubject.send(true)
        #expect(await wait(until: { viewModel.isFailed }))

        isResolving.withLock { $0 = false }
        dataProvider.loads.removeAll()

        // The same link again, on the tag the failed list already carries.
        viewModel.select(categoryId: "layer-1")
        #expect(await wait(until: { isResolving.withLock { $0 } }))

        viewModel.onRetry()

        #expect(await wait(until: { dataProvider.loads.isNotEmpty }))
        #expect(dataProvider.loads.map(\.tag) == [PulseTagSelection(id: "layer-1", name: "Layer 1 (L1)", country: "US")])
    }

    // MARK: - Helpers

    private func makeViewModel(
        dataProvider: StubPulseDataProvider,
        router: StubCryptoFeedRoutable = StubCryptoFeedRoutable(),
        result: Result<MarketsGeckoCategoriesSnapshot, Error> = .success(snapshot(country: nil)),
        delay: Duration = .zero,
        onRequest: @escaping @Sendable () -> Void = {}
    ) -> PulseViewModel {
        makeViewModel(
            dataProvider: dataProvider,
            router: router,
            onRequest: onRequest,
            delayForRequest: { _ in delay },
            resultForRequest: { _ in result }
        )
    }

    private func makeViewModel(
        dataProvider: StubPulseDataProvider,
        router: StubCryptoFeedRoutable = StubCryptoFeedRoutable(),
        ignoresCancellation: Bool = false,
        onRequest: @escaping @Sendable () -> Void = {},
        delayForRequest: @escaping @Sendable (Int) -> Duration,
        resultForRequest: @escaping @Sendable (Int) -> Result<MarketsGeckoCategoriesSnapshot, Error>
    ) -> PulseViewModel {
        PulseViewModel(
            dataProvider: dataProvider,
            router: router,
            geckoCategoriesProvider: StubGeckoCategoriesProvider(
                delay: delayForRequest,
                ignoresCancellation: ignoresCancellation,
                onRequest: onRequest,
                result: resultForRequest
            )
        )
    }

    private func wait(until condition: () -> Bool, timeout: Duration = .seconds(5)) async -> Bool {
        let deadline = ContinuousClock.now + timeout

        while !condition(), ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(5))
        }

        return condition()
    }
}

private func snapshot(country: String?) -> MarketsGeckoCategoriesSnapshot {
    MarketsGeckoCategoriesSnapshot(categories: MarketsGeckoCategoriesFixture.all, country: country)
}

// MARK: - Stubs

private final class StubPulseDataProvider: PulseDataProvider {
    struct Load: Equatable {
        let interval: PulseInterval
        let category: PulseCategory
        let tag: PulseTagSelection?
        let isCategoryUserInitiated: Bool
    }

    var loads: [Load] = []

    let tokensSubject = CurrentValueSubject<[MarketsTokenModel], Never>([])
    let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    let failedSubject = CurrentValueSubject<Bool, Never>(false)

    var tokensPublisher: AnyPublisher<[MarketsTokenModel], Never> { tokensSubject.eraseToAnyPublisher() }
    var failedPublisher: AnyPublisher<Bool, Never> { failedSubject.eraseToAnyPublisher() }
    var isLoadingPublisher: AnyPublisher<Bool, Never> { isLoadingSubject.eraseToAnyPublisher() }
    var canLoadMore: Bool { false }

    func makeRowViewModel(for token: MarketsTokenModel, onTap: @escaping () -> Void) -> MarketTokenItemViewModel {
        fatalError("Not needed: the stub never publishes tokens")
    }

    func load(interval: PulseInterval, category: PulseCategory, tag: PulseTagSelection?, isCategoryUserInitiated: Bool) {
        loads.append(Load(interval: interval, category: category, tag: tag, isCategoryUserInitiated: isCategoryUserInitiated))
    }

    func loadMore() {}
    func setVisibleTokenIDs(_ ids: Set<String>) {}
    func suspendQuotes() {}
    func resumeQuotes() {}
}

private struct StubGeckoCategoriesProvider: MarketsGeckoCategoriesProvider {
    let delay: @Sendable (Int) -> Duration
    let ignoresCancellation: Bool
    let onRequest: @Sendable () -> Void
    let result: @Sendable (Int) -> Result<MarketsGeckoCategoriesSnapshot, Error>

    private let requestCount = OSAllocatedUnfairLock(initialState: 0)

    func categories() async throws -> MarketsGeckoCategoriesSnapshot {
        let index = requestCount.withLock { count in
            defer { count += 1 }
            return count
        }

        onRequest()

        if delay(index) > .zero {
            // `ignoresCancellation` — a backend that answers a request already dropped, with an error of its own.
            if ignoresCancellation {
                try? await Task.sleep(for: delay(index))
            } else {
                try await Task.sleep(for: delay(index))
            }
        }

        return try result(index).get()
    }
}

private final class StubCryptoFeedRoutable: CryptoFeedRoutable {
    var tagFilterInputs: [PulseTagFilterInput] = []

    func openToken(_ token: MarketsTokenModel) {}
    func openPulseTagFilter(with input: PulseTagFilterInput) { tagFilterInputs.append(input) }
    func openMarketCapInfo(subject: MarketCapInfoSubject) {}
    func openPortfolioToken(_ walletModel: any WalletModel) {}
    func choosePortfolioToken(from walletModels: [any WalletModel]) {}
}
