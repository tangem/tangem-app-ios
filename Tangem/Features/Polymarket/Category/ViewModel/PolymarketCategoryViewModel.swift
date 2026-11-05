//
//  PolymarketCategoryViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

@MainActor
final class PolymarketCategoryViewModel: ObservableObject {
    let title: String
    let eventsViewModel: PolymarketEventsBlockViewModel

    private let refreshCenter: PolymarketMainRefreshCenter
    private weak var coordinator: PolymarketCategoryRoutable?

    init(
        category: PolymarketCategory,
        eventsViewModel: PolymarketEventsBlockViewModel,
        refreshCenter: PolymarketMainRefreshCenter,
        coordinator: PolymarketCategoryRoutable?
    ) {
        title = category.label
        self.eventsViewModel = eventsViewModel
        self.refreshCenter = refreshCenter
        self.coordinator = coordinator
    }
}

// MARK: - View actions

extension PolymarketCategoryViewModel {
    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .close:
            coordinator?.closeCategory()
        }
    }

    enum ViewAction {
        case close
    }
}

// MARK: - Refresh

extension PolymarketCategoryViewModel {
    func refresh() async {
        await refreshCenter.refresh(.full)
    }
}
