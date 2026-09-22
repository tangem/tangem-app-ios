//
//  FeedViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemUI

final class FeedViewModel: ObservableObject {
    let searchBarViewModel: FeedSearchBarViewModel
    let searchViewModel: FeedSearchViewModel
    let tabsViewModel: FeedTabsViewModel
    let widgetsViewModel: FeedWidgetsViewModel

    private var isSheetOpened = false

    private var bag = Set<AnyCancellable>()

    init(
        searchBarViewModel: FeedSearchBarViewModel,
        searchViewModel: FeedSearchViewModel,
        tabsViewModel: FeedTabsViewModel,
        widgetsViewModel: FeedWidgetsViewModel,
        shtorkaActions: any MainShtorkaViewActionProvider
    ) {
        self.searchBarViewModel = searchBarViewModel
        self.searchViewModel = searchViewModel
        self.tabsViewModel = tabsViewModel
        self.widgetsViewModel = widgetsViewModel

        bind(to: shtorkaActions)
    }
}

// MARK: - Private

private extension FeedViewModel {
    func bind(to shtorkaActions: any MainShtorkaViewActionProvider) {
        shtorkaActions
            .sizePublisher
            // The size the feed opens with is already what it renders; only a change asks it for anything.
            .dropFirst()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, size in
                viewModel.sheetSizeDidChange(to: size)
            }
            .store(in: &bag)
    }

    func sheetSizeDidChange(to size: ShtorkaSize) {
        switch size {
        case .collapsed:
            isSheetOpened = false
        case .medium, .full:
            logScreenOpenedIfNeeded()
            widgetsViewModel.refresh()
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
