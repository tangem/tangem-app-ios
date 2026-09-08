//
//  PulseViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemUI

final class PulseViewModel: ObservableObject {
    @Published private(set) var tokens: [MarketTokenItemViewModel] = []
    @Published private(set) var selectedInterval: PulseInterval = .day
    @Published private(set) var selectedCategory: PulseCategory = .marketCap
    @Published private(set) var isCategoriesExpanded = false
    @Published private(set) var isFailed = false

    let intervals = PulseInterval.allCases
    let categories = PulseCategory.allCases

    private let dataProvider: PulseDataProvider
    private weak var routable: (any FeedRoutable)?
    private var rowViewModels: [String: MarketTokenItemViewModel] = [:]
    private var visibleTokenIDs: Set<String> = []
    private var isLoaded = false
    private var bag = Set<AnyCancellable>()

    init(dataProvider: PulseDataProvider, routable: any FeedRoutable) {
        self.dataProvider = dataProvider
        self.routable = routable

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
        dataProvider.load(interval: interval, category: selectedCategory)
    }

    func onToggleCategories() {
        isCategoriesExpanded.toggle()
    }

    func onSelectCategory(_ category: PulseCategory) {
        guard selectedCategory != category else { return }

        selectedCategory = category
        dataProvider.load(interval: selectedInterval, category: category)
    }

    func onSelectToken(_ token: MarketsTokenModel) {
        routable?.openToken(token)
    }

    func onRetry() {
        dataProvider.load(interval: selectedInterval, category: selectedCategory)
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
    }

    private func makeRows(for tokens: [MarketsTokenModel]) -> [MarketTokenItemViewModel] {
        var reused: [String: MarketTokenItemViewModel] = [:]

        let rows = tokens.map { token in
            let row = rowViewModels[token.id] ?? dataProvider.makeRowViewModel(for: token) { [weak self] in
                self?.onSelectToken(token)
            }

            reused[token.id] = row
            return row
        }

        rowViewModels = reused

        return rows
    }

    private func loadIfNeeded() {
        guard !isLoaded || isFailed else { return }

        isLoaded = true
        dataProvider.load(interval: selectedInterval, category: selectedCategory)
    }
}
