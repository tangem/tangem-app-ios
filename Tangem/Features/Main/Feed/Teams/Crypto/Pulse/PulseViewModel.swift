//
//  PulseViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
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

    var contentState: ContentState {
        ContentState(isEmpty: tokens.isEmpty, isLoading: isLoading, isFailed: isFailed)
    }

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

    private let skeletonFloor = LoadingStateFloor()

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
        Publishers
            .CombineLatest3(
                dataProvider.tokensPublisher,
                dataProvider.isLoadingPublisher,
                dataProvider.failedPublisher
            )
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, state in
                let (tokens, isLoading, isFailed) = state
                viewModel.apply(tokens: tokens, isLoading: isLoading, isFailed: isFailed)
            }
            .store(in: &bag)
    }

    private func apply(tokens: [MarketsTokenModel], isLoading: Bool, isFailed: Bool) {
        let incomingState = ContentState(isEmpty: tokens.isEmpty, isLoading: isLoading, isFailed: isFailed)

        guard incomingState != .skeletons else {
            skeletonFloor.startIfNeeded()
            commit(tokens: tokens, isLoading: isLoading, isFailed: isFailed)
            return
        }

        skeletonFloor.release { [weak self] in
            self?.commit(tokens: tokens, isLoading: isLoading, isFailed: isFailed)
        }
    }

    private func commit(tokens: [MarketsTokenModel], isLoading: Bool, isFailed: Bool) {
        self.tokens = makeRows(for: tokens)
        self.isLoading = isLoading
        self.isFailed = isFailed
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
        // Only a failure the user actually sees is worth a reload — a failed page append keeps the list and its scroll position
        guard !isLoaded || contentState == .failure else { return }

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

// MARK: - ContentState

extension PulseViewModel {
    enum ContentState: Hashable {
        case failure
        case skeletons
        case empty
        case rows

        init(isEmpty: Bool, isLoading: Bool, isFailed: Bool) {
            switch (isEmpty, isLoading, isFailed) {
            // A failure outranks loading, so a failed empty list is never "still in skeletons"
            case (true, _, true): self = .failure
            case (true, true, false): self = .skeletons
            case (true, false, false): self = .empty
            case (false, _, _): self = .rows
            }
        }
    }
}

// MARK: - Constants

private extension PulseViewModel {
    enum Constants {
        /// Applying an empty filter is a category choice too — the whole market, the counterpart of the Real assets umbrella.
        static let allTagsAnalyticsValue = "all"
    }
}
