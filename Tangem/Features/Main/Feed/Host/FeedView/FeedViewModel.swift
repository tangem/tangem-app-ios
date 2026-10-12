//
//  FeedViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemUI

final class FeedViewModel: ObservableObject {
    @Published private(set) var isContentUnderSearchBar = false

    let searchBarViewModel: FeedSearchBarViewModel
    let searchViewModel: FeedSearchViewModel
    let tabsViewModel: FeedTabsViewModel
    let widgetsViewModel: FeedWidgetsViewModel

    private let scrollCoordinator = FeedScrollCoordinator()
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

    func widgetsHeightDidChange(_ height: CGFloat) {
        scrollCoordinator.report(widgets: height)
    }

    func scrollOffsetDidChange(_ offset: CGFloat) {
        scrollCoordinator.report(offset: offset, tabID: tabsViewModel.selectedTab.id)

        let isUnderSearchBar = offset > 0
        if isUnderSearchBar != isContentUnderSearchBar {
            isContentUnderSearchBar = isUnderSearchBar
        }
    }

    func scrollTarget(viewportHeight: CGFloat) -> (String, Bool, Bool) -> FeedScrollTarget? {
        { [weak self] tabID, pinTabs, chipsPinned in
            self?.scrollCoordinator.scrollTarget(
                forTab: tabID,
                viewportHeight: viewportHeight,
                pinTabs: pinTabs,
                chipsPinned: chipsPinned
            )
        }
    }

    func resetScroll() {
        resetSavedScrollPositions()
        if isContentUnderSearchBar {
            isContentUnderSearchBar = false
        }
    }

    func resetSavedScrollPositions() {
        scrollCoordinator.reset()
    }
}

// MARK: - Private

private extension FeedViewModel {
    func bind(to container: any FeedContainer) {
        searchViewModel
            .$isActive
            .removeDuplicates()
            .receiveOnMain()
            .sink { [weak container] isActive in
                container?.setSearchActive(isActive)
            }
            .store(in: &bag)

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
