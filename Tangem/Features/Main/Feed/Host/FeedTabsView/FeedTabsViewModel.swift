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

    init(tabs: [FeedTab]) {
        self.tabs = tabs

        selectedTab = tabs[0]
    }

    func onSelectTab(_ tab: FeedTab) {
        guard selectedTab.id != tab.id else {
            return
        }

        selectedTab = tab
    }

    func sheetSizeDidChange(to size: ShtorkaSize) {
        tabs.forEach { $0.feedSheetSizeDidChange(to: size) }
    }
}
