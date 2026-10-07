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
        let state = ContentState(isEmpty: tokens.isEmpty, isLoading: isLoading, isFailed: isFailed)

        // A list held back by an unresolved category is on its way rather than failed: the reload its retry
        // button would offer is the one that resolution is about to ask for.
        return state == .failure && pendingCategoryId != nil ? .skeletons : state
    }

    var categories: [PulseCategory] {
        selectedTag == nil ? PulseCategory.allCases : PulseCategory.supportedWithTag
    }

    var tagChipTitle: String {
        selectedTag?.name ?? Localization.marketCategories
    }

    private let dataProvider: PulseDataProvider
    private let router: any CryptoFeedRoutable
    private let geckoCategoriesProvider: MarketsGeckoCategoriesProvider
    private var rowViewModels: [String: MarketTokenItemViewModel] = [:]
    private var visibleTokenIDs: Set<String> = []
    private var isLoaded = false
    private var requestedTagTask: Task<Void, Never>?
    /// Published: it decides whether a failed list is still shown as failed.
    @Published private var pendingCategoryId: String?
    private var bag = Set<AnyCancellable>()

    private let skeletonFloor = LoadingStateFloor()

    init(
        dataProvider: PulseDataProvider,
        router: any CryptoFeedRoutable,
        geckoCategoriesProvider: MarketsGeckoCategoriesProvider = InjectedValues[\.marketsGeckoCategoriesProvider]
    ) {
        self.dataProvider = dataProvider
        self.router = router
        self.geckoCategoriesProvider = geckoCategoriesProvider

        bind()
    }

    deinit {
        requestedTagTask?.cancel()
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

                self?.applyUserSelected(tag: selection)
            }
        )

        router.openPulseTagFilter(with: input)
    }

    func onTagClearTap() {
        applyUserSelected(tag: nil)
    }

    func select(categoryId: String) {
        requestedTagTask?.cancel()
        pendingCategoryId = categoryId

        let geckoCategoriesProvider = geckoCategoriesProvider

        requestedTagTask = Task { @MainActor [weak self] in
            do {
                let snapshot = try await geckoCategoriesProvider.categories()
                try Task.checkCancellation()

                guard let self else { return }

                pendingCategoryId = nil

                guard let category = snapshot.categories.first(where: { $0.id == categoryId }) else {
                    loadIfNeeded()
                    return
                }

                apply(resolved: PulseTagSelection(id: category.id, name: category.name, country: snapshot.country))
            } catch {
                // Cancellation is the one outcome that leaves the state alone: a newer resolution already owns
                // it. Anything else is this resolution's own failure, and the list it was holding back is owed
                // a load however the failure is dressed.
                guard !Task.isCancelled, let self else { return }

                AppLogger.tag("Markets").error("Failed to resolve the requested gecko category", error: error)

                pendingCategoryId = nil
                loadIfNeeded()
            }
        }
    }

    func onSelectToken(_ token: MarketsTokenModel) {
        Analytics.log(
            event: .marketsChartScreenOpened,
            params: [
                .source: Analytics.ParameterValue.main.rawValue,
                .token: token.symbol.uppercased(),
            ]
        )

        router.openToken(token)
    }

    func onRetry() {
        // A list still waiting for its category would be reloaded on the filter it is about to leave.
        guard pendingCategoryId == nil else { return }

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

    private func apply(resolved tag: PulseTagSelection) {
        // The tag already shown asks for no list of its own, but the one this resolution was holding back —
        // the retry it swallowed among them — has still never been asked for.
        guard tag != selectedTag else {
            loadIfNeeded()
            return
        }

        select(tag: tag)
    }

    private func applyUserSelected(tag: PulseTagSelection?) {
        requestedTagTask?.cancel()
        requestedTagTask = nil
        pendingCategoryId = nil

        // The same tag asks for no list of its own, and the one the dropped resolution was holding back has
        // still never been asked for.
        guard tag != selectedTag else {
            loadIfNeeded()
            return
        }

        select(tag: tag)
    }

    private func select(tag: PulseTagSelection?) {
        guard tag != selectedTag else { return }

        selectedTag = tag

        let isCategoryDropped = !categories.contains(selectedCategory)

        if isCategoryDropped {
            selectedCategory = .marketCap
        }

        isLoaded = true

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
        guard pendingCategoryId == nil, !isLoaded || contentState == .failure else { return }

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
