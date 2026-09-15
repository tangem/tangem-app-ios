//
//  FeedTabsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemUI

final class FeedTabsViewModel: ObservableObject {
    @Published private(set) var selectedTab: FeedTab

    let tabs: [FeedTab]

    private var sheetSize: ShtorkaSize = .collapsed

    init(tabs: [FeedTab]) {
        self.tabs = tabs

        selectedTab = tabs[0]
    }

    func onSelectTab(_ tab: FeedTab) {
        guard selectedTab.id != tab.id else {
            return
        }

        selectedTab = tab

        if let section = tab.kind.analyticsSection {
            Analytics.log(event: .marketsEnterSection, params: [.section: section.rawValue])
        }

        updatePromoBannersVisibility()
    }

    func sheetSizeDidChange(to size: ShtorkaSize) {
        sheetSize = size
        tabs.forEach { $0.feedSheetSizeDidChange(to: size) }
        updatePromoBannersVisibility()
    }

    /// Only the selected tab is rendered, so every other tab's banner has to be reported as hidden — otherwise it
    /// logs itself as shown while the user never sees it, and stays silent when they finally switch to that tab.
    private func updatePromoBannersVisibility() {
        for tab in tabs {
            let isVisible = tab.id == selectedTab.id && sheetSize != .collapsed
            tab.promoBanner?.onScreenVisibilityChange(isVisible: isVisible)
        }
    }
}
