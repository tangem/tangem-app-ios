//
//  FeedSearchTabsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

final class FeedSearchTabsViewModel: ObservableObject {
    @Published private(set) var selectedTab: FeedSearchTab

    let tabs: [FeedSearchTab]

    private var isSearching = false

    init(tabs: [FeedSearchTab]) {
        self.tabs = tabs

        selectedTab = tabs[0]
    }

    func onSelectTab(_ tab: FeedSearchTab) {
        guard selectedTab.id != tab.id else {
            return
        }

        selectedTab = tab
        syncVisibility()
    }

    func setSearching(_ isSearching: Bool) {
        self.isSearching = isSearching
        syncVisibility()
    }

    private func syncVisibility() {
        for tab in tabs {
            tab.setVisible(isSearching && tab.id == selectedTab.id)
        }
    }
}
