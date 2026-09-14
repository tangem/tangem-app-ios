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
            searchViewModel.reset()
        case .medium:
            searchViewModel.close()
        case .full:
            break
        }

        tabsViewModel.sheetSizeDidChange(to: size)
    }
}
