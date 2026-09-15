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
        let viewModel = PulseViewModel(dataProvider: dataProvider, router: StubCryptoFeedRoutable())

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
        let viewModel = PulseViewModel(dataProvider: dataProvider, router: router)
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
        let viewModel = PulseViewModel(dataProvider: dataProvider, router: router)
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

    var tokensPublisher: AnyPublisher<[MarketsTokenModel], Never> { Empty().eraseToAnyPublisher() }
    var failedPublisher: AnyPublisher<Bool, Never> { Empty().eraseToAnyPublisher() }
    var isLoadingPublisher: AnyPublisher<Bool, Never> { Empty().eraseToAnyPublisher() }
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

private final class StubCryptoFeedRoutable: CryptoFeedRoutable {
    var tagFilterInputs: [PulseTagFilterInput] = []

    func openToken(_ token: MarketsTokenModel) {}
    func openPulseTagFilter(with input: PulseTagFilterInput) { tagFilterInputs.append(input) }
    func openMarketCapInfo(subject: MarketCapInfoSubject) {}
    func openPortfolioToken(_ walletModel: any WalletModel) {}
    func choosePortfolioToken(from walletModels: [any WalletModel]) {}
}
