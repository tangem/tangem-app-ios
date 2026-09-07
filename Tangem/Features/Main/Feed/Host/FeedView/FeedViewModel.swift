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

    private weak var routable: (any FeedRoutable)?

    init(
        searchBarViewModel: FeedSearchBarViewModel,
        searchViewModel: FeedSearchViewModel,
        tabsViewModel: FeedTabsViewModel,
        widgetsViewModel: FeedWidgetsViewModel,
        routable: any FeedRoutable
    ) {
        self.searchBarViewModel = searchBarViewModel
        self.searchViewModel = searchViewModel
        self.tabsViewModel = tabsViewModel
        self.widgetsViewModel = widgetsViewModel
        self.routable = routable
    }

    func sheetSizeDidChange(to size: ShtorkaSize) {
        switch size {
        case .collapsed:
            routable?.returnToRoot()
            searchViewModel.reset()
        case .medium:
            searchViewModel.close()
        case .full:
            break
        }

        tabsViewModel.sheetSizeDidChange(to: size)
    }
}
