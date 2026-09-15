//
//  PulseViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemLocalization
import TangemUI

final class PulseViewModel: ObservableObject {
    @Published private(set) var tokens: [MarketTokenItemViewModel] = []
    @Published private(set) var selectedInterval: PulseInterval = .day
    @Published private(set) var selectedCategory: PulseCategory = .marketCap
    @Published private(set) var selectedTag: PulseTagSelection?
    @Published private(set) var isFailed = false
    @Published private(set) var isLoading = true

    let intervals = PulseInterval.allCases

    var categories: [PulseCategory] {
        selectedTag == nil ? PulseCategory.allCases : PulseCategory.supportedWithTag
    }

    var tagChipTitle: String {
        selectedTag?.name ?? Localization.marketCategories
    }

    private let dataProvider: PulseDataProvider
    private let router: any CryptoFeedRoutable
    private var rowViewModels: [String: MarketTokenItemViewModel] = [:]
    private var visibleTokenIDs: Set<String> = []
    private var isLoaded = false
    private var bag = Set<AnyCancellable>()

    init(dataProvider: PulseDataProvider, router: any CryptoFeedRoutable) {
        self.dataProvider = dataProvider
        self.router = router

        bind()
    }

    deinit {
        AppLogger.debug("PulseViewModel deinit")
    }

    func onViewAppear() {
        loadIfNeeded()
    }

    func feedSheetSizeDidChange(to size: ShtorkaSize) {
        guard size != .collapsed else {
            dataProvider.suspendQuotes()
            return
        }

        loadIfNeeded()
        dataProvider.resumeQuotes()
    }

    func onSelectInterval(_ interval: PulseInterval) {
        guard selectedInterval != interval else { return }

        selectedInterval = interval
        load()
    }

    func onSelectCategory(_ category: PulseCategory) {
        guard selectedCategory != category else { return }

        selectedCategory = category
        load()
    }

    func onTagChipTap() {
        let input = PulseTagFilterInput(
            selectedTagID: selectedTag?.id,
            onApply: { [weak self] selection in
                Analytics.log(
                    event: .marketsSelectCategory,
                    params: [
                        .section: Analytics.MarketsSection.crypto.rawValue,
                        .category: selection?.id ?? Constants.allTagsAnalyticsValue,
                    ]
                )

                self?.select(tag: selection)
            }
        )

        router.openPulseTagFilter(with: input)
    }

    func onTagClearTap() {
        select(tag: nil)
    }

    func onSelectToken(_ token: MarketsTokenModel) {
        router.openToken(token)
    }

    func onRetry() {
        load()
    }

    func onTokenAppear(_ token: MarketTokenItemViewModel) {
        visibleTokenIDs.insert(token.tokenId)
        dataProvider.setVisibleTokenIDs(visibleTokenIDs)

        if token.tokenId == tokens.last?.tokenId {
            dataProvider.loadMore()
        }
    }

    func onTokenDisappear(_ token: MarketTokenItemViewModel) {
        visibleTokenIDs.remove(token.tokenId)
        dataProvider.setVisibleTokenIDs(visibleTokenIDs)
    }

    private func select(tag: PulseTagSelection?) {
        guard tag != selectedTag else { return }

        selectedTag = tag

        let isCategoryDropped = !categories.contains(selectedCategory)

        if isCategoryDropped {
            selectedCategory = .marketCap
        }

        load(isCategoryUserInitiated: !isCategoryDropped)
    }

    private func bind() {
        dataProvider
            .tokensPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, tokens in
                viewModel.tokens = viewModel.makeRows(for: tokens)
            }
            .store(in: &bag)

        dataProvider
            .failedPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, isFailed in
                viewModel.isFailed = isFailed
            }
            .store(in: &bag)

        dataProvider
            .isLoadingPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, isLoading in
                viewModel.isLoading = isLoading
            }
            .store(in: &bag)
    }

    private func makeRows(for tokens: [MarketsTokenModel]) -> [MarketTokenItemViewModel] {
        var reused: [String: MarketTokenItemViewModel] = [:]

        let rows = tokens.map { token in
            let row = rowViewModels[token.id] ?? dataProvider.makeRowViewModel(for: token) { [weak self] in
                self?.onSelectToken(token)
            }

            row.updateRestriction(from: token)
            reused[token.id] = row
            return row
        }

        rowViewModels = reused

        return rows
    }

    private func loadIfNeeded() {
        guard !isLoaded || isFailed else { return }

        isLoaded = true
        load()
    }

    private func load(isCategoryUserInitiated: Bool = true) {
        dataProvider.load(
            interval: selectedInterval,
            category: selectedCategory,
            tag: selectedTag,
            isCategoryUserInitiated: isCategoryUserInitiated
        )
    }
}

// MARK: - Constants

private extension PulseViewModel {
    enum Constants {
        /// Applying an empty filter is a category choice too — the whole market, the counterpart of the Real assets umbrella.
        static let allTagsAnalyticsValue = "all"
    }
}
