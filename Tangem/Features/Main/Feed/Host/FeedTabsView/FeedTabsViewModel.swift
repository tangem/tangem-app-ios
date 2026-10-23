//
//  FeedTabsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemUI

final class FeedTabsViewModel: ObservableObject {
    @Published private(set) var selectedTab: FeedTab

    let tabs: [FeedTab]
    let pager: FeedTabPager<FeedTab>

    var tabSelectionPublisher: AnyPublisher<FeedTab, Never> {
        tabSelectionSubject.eraseToAnyPublisher()
    }

    private let tabSelectionSubject = PassthroughSubject<FeedTab, Never>()
    private var sheetSize: ShtorkaSize = .collapsed

    init(tabs: [FeedTab]) {
        self.tabs = tabs

        selectedTab = tabs[0]
        pager = FeedTabPager(tabs: tabs, selectedTab: tabs[0])
    }

    func requestTabSelection(_ tab: FeedTab) {
        tabSelectionSubject.send(tab)
    }

    func onSelectTab(_ tab: FeedTab) {
        guard selectedTab.id != tab.id else {
            return
        }

        selectedTab = tab

        if let section = tab.kind.analyticsSection {
            Analytics.log(event: .marketsEnterSection, params: [.section: section.rawValue])
        }
    }

    func selectTab(kind: FeedTabKind) {
        let tab = tabs.first { $0.kind == kind } ?? tabs[0]

        onSelectTab(tab)
        movePage(to: tab)
    }

    func sheetSizeDidChange(to size: ShtorkaSize) {
        sheetSize = size
        tabs.forEach { $0.feedSheetSizeDidChange(to: size) }
        updatePromoBannersVisibility()
    }

    // MARK: - Switching

    func resolve(_ target: FeedScrollTarget?) -> FeedScrollTarget? {
        switch target {
        case .jump(let anchor, let shift):
            // Restore before the slide in either direction. Compensating the outgoing pages
            // keeps them in place without changing the scroll offset again at completion.
            pager.resetCurrentInset()
            pager.shiftDepartingInsets(by: shift)
            return .jump(anchor: anchor, shift: shift)
        case .pinTabs, .scroll:
            pager.resetInsets()
            return target
        case nil:
            pager.resetCurrentInset()
            return nil
        }
    }

    func pagesDidSettle() {
        updatePromoBannersVisibility()
    }

    /// Select the page without animating or touching the scroll; the pager may not be mounted yet.
    private func movePage(to tab: FeedTab) {
        guard pager.currentPage.id != tab.id else {
            return
        }

        pager.show(tab, topInset: pager.currentPage.topInset)
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
