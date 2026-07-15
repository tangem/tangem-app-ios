//
//  PortfolioTokenListViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class PortfolioTokenListViewModel: ObservableObject {
    // MARK: - Properties

    private var baseItems: [ForYouTokenListItem]
    private var expandedIds: Set<String> = []

    // MARK: - Publishers

    @Published private(set) var items: [ForYouTokenListItem]

    // MARK: - Init

    init(items: [ForYouTokenListItem]) {
        baseItems = items
        self.items = items
    }

    // MARK: - Methods

    func update(items: [ForYouTokenListItem]) {
        baseItems = items
        recompute()
    }

    func toggleAsset(id: String) {
        guard baseItems.first(where: { $0.id == id })?.isExpandable == true else {
            return
        }

        // Toggle: adds the id if absent, removes it if present.
        expandedIds.formSymmetricDifference([id])
        recompute()
    }
}

// MARK: - Private logic

private extension PortfolioTokenListViewModel {
    func recompute() {
        items = baseItems.expanded(expandedIds)
    }
}

// MARK: - Private helpers

private extension [ForYouTokenListItem] {
    /// Re-derives each item's `isExpanded` flag from the currently expanded asset ids.
    func expanded(_ expandedIds: Set<String>) -> [ForYouTokenListItem] {
        map { $0.updating(isExpanded: expandedIds.contains($0.id)) }
    }
}

private extension ForYouTokenListItem {
    func updating(isExpanded: Bool) -> ForYouTokenListItem {
        ForYouTokenListItem(
            id: id,
            assetRow: assetRow,
            networkRows: networkRows,
            isExpanded: isExpanded,
            isExpandable: isExpandable
        )
    }
}
