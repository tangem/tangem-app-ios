//
//  PulseTagFilterBottomSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

@MainActor
final class PulseTagFilterBottomSheetViewModel: ObservableObject {
    @Published private(set) var loadingState: LoadingState = .loading
    @Published private(set) var selectedTagID: String?
    @Published private(set) var featuredItems: [Item] = []
    @Published private(set) var categoryItems: [Item] = []

    @Published var searchText: String = "" {
        didSet { applySearch() }
    }

    var showsNoResults: Bool {
        loadingState == .loaded && categoryItems.isEmpty
    }

    var showsFooter: Bool {
        loadingState == .loaded && selectedTagID != appliedTagID
    }

    private let appliedTagID: String?
    private var items: [Item] = []
    private var snapshot: MarketsGeckoCategoriesSnapshot?
    private var loadingTask: Task<Void, Never>?

    private let categoriesProvider: MarketsGeckoCategoriesProvider
    private let marketCapFormatter: MarketCapFormatter
    private let onApply: (PulseTagSelection?) -> Void
    private let dismissAction: () -> Void

    init(
        input: PulseTagFilterInput,
        categoriesProvider: MarketsGeckoCategoriesProvider = InjectedValues[\.marketsGeckoCategoriesProvider],
        marketCapFormatter: MarketCapFormatter? = nil,
        onDismiss: @escaping () -> Void
    ) {
        selectedTagID = input.selectedTagID
        appliedTagID = input.selectedTagID
        onApply = input.onApply
        self.categoriesProvider = categoriesProvider
        self.marketCapFormatter = marketCapFormatter ?? MarketCapFormatter(
            divisorsList: AmountNotationSuffixFormatter.Divisor.defaultList,
            baseCurrencyCode: AppSettings.shared.selectedCurrencyCode,
            notationFormatter: DefaultAmountNotationFormatter()
        )
        dismissAction = onDismiss
    }

    func onViewAppear() {
        guard loadingTask == nil, snapshot == nil else { return }

        load()
    }

    func onViewDisappear() {
        loadingTask?.cancel()
        loadingTask = nil
    }

    func retry() {
        load()
    }

    func isSelected(_ item: Item) -> Bool {
        item.id == selectedTagID
    }

    func select(_ item: Item) {
        guard item.id != selectedTagID else { return }

        selectedTagID = item.id
    }

    func reset() {
        selectedTagID = nil
    }

    /// A selection that cannot be resolved against the loaded categories is left untouched rather than cleared:
    /// the user did not ask to drop the tag, the sheet just failed to show it.
    func apply() {
        defer { dismiss() }

        guard let selectedTagID else {
            onApply(nil)
            return
        }

        guard let snapshot, let tag = snapshot.categories.first(where: { $0.id == selectedTagID }) else {
            return
        }

        onApply(PulseTagSelection(id: tag.id, name: tag.name, country: snapshot.country))
    }

    func close() {
        dismiss()
    }

    private func load() {
        loadingTask?.cancel()
        loadingState = .loading

        loadingTask = Task { [weak self] in
            guard let self else { return }

            do {
                let snapshot = try await categoriesProvider.categories()
                try Task.checkCancellation()

                guard !snapshot.categories.isEmpty else {
                    throw PulseTagFilterError.noCategories
                }

                self.snapshot = snapshot
                items = snapshot.categories.map(makeItem)
                applySearch()
                loadingState = .loaded
            } catch {
                guard !error.isCancellationError else { return }

                AppLogger.tag("Markets").error("Failed to load gecko categories for the tag filter", error: error)
                loadingState = .failed
            }
        }
    }

    private func makeItem(_ category: MarketsDTO.GeckoCategories.Category) -> Item {
        Item(
            id: category.id,
            title: category.name,
            marketCap: marketCapFormatter.formatMarketCap(category.marketCap),
            tokensCount: category.tokensCount,
            isFeatured: category.featured
        )
    }

    private func applySearch() {
        let query = searchText.trimmed()
        let matching = query.isEmpty ? items : items.filter { $0.title.localizedCaseInsensitiveContains(query) }

        categoryItems = matching
        featuredItems = matching.filter(\.isFeatured)
    }

    private func dismiss() {
        loadingTask?.cancel()
        dismissAction()
    }
}

extension PulseTagFilterBottomSheetViewModel {
    enum LoadingState: Equatable {
        case loading
        case failed
        case loaded
    }

    struct Item: Identifiable, Hashable {
        let id: String
        let title: String
        let marketCap: String
        let tokensCount: Int
        let isFeatured: Bool
    }

    private enum PulseTagFilterError: Error {
        case noCategories
    }
}
