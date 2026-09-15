//
//  FeedViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemUI

final class FeedViewModel: ObservableObject {
    let searchBarViewModel: FeedSearchBarViewModel
    let searchViewModel: FeedSearchViewModel
    let tabsViewModel: FeedTabsViewModel
    let widgetsViewModel: FeedWidgetsViewModel

    private var isSheetOpened = false

    init(
        searchBarViewModel: FeedSearchBarViewModel,
        searchViewModel: FeedSearchViewModel,
        tabsViewModel: FeedTabsViewModel,
        widgetsViewModel: FeedWidgetsViewModel
    ) {
        self.searchBarViewModel = searchBarViewModel
        self.searchViewModel = searchViewModel
        self.tabsViewModel = tabsViewModel
        self.widgetsViewModel = widgetsViewModel
    }

    func sheetSizeDidChange(to size: ShtorkaSize) {
        switch size {
        case .collapsed:
            isSheetOpened = false
            searchViewModel.reset()
        case .medium:
            logScreenOpenedIfNeeded()
            searchViewModel.close()
        case .full:
            logScreenOpenedIfNeeded()
        }

        tabsViewModel.sheetSizeDidChange(to: size)
    }

    /// The sheet reports every size change, so an opening is logged once until it collapses back.
    private func logScreenOpenedIfNeeded() {
        guard !isSheetOpened else {
            return
        }

        isSheetOpened = true

        var params: [Analytics.ParameterKey: String] = [:]

        if let section = tabsViewModel.selectedTab.kind.analyticsSection {
            params[.section] = section.rawValue
        }

        Analytics.log(event: .marketsScreenOpened, params: params)
    }
}
