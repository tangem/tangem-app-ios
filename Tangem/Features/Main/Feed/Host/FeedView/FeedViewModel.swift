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
    let scrollCoordinator = FeedScrollCoordinator()

    private var isSheetOpened = false

    private var bag = Set<AnyCancellable>()

    init(
        searchBarViewModel: FeedSearchBarViewModel,
        searchViewModel: FeedSearchViewModel,
        tabsViewModel: FeedTabsViewModel,
        widgetsViewModel: FeedWidgetsViewModel,
        container: any FeedContainer,
        selection: FeedSelection?
    ) {
        self.searchBarViewModel = searchBarViewModel
        self.searchViewModel = searchViewModel
        self.tabsViewModel = tabsViewModel
        self.widgetsViewModel = widgetsViewModel

        // Before the container is listened to: the size it reports counts the feed as opened, and it has to be
        // opened on the section the link named rather than on the default one.
        if let selection {
            apply(selection: selection)
        }

        bind(to: container)
    }

    func apply(selection: FeedSelection) {
        tabsViewModel.selectTab(kind: selection.tabKind)
        tabsViewModel.selectedTab.apply(selection: selection)
    }
}

// MARK: - Private

private extension FeedViewModel {
    func bind(to container: any FeedContainer) {
        container
            .sizePublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, size in
                viewModel.sizeDidChange(to: size)
            }
            .store(in: &bag)
    }

    func sizeDidChange(to size: ShtorkaSize) {
        switch size {
        case .collapsed:
            isSheetOpened = false
        case .medium, .full:
            logScreenOpenedIfNeeded()
            widgetsViewModel.refresh()
        }

        // Where each tab was left is worth restoring within one reading of the feed; a feed the user comes back
        // to starts from the top.
        if size != .full {
            scrollCoordinator.reset()
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
