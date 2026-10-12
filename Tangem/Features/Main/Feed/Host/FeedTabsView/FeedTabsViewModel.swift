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
    @Published private(set) var currentPage: FeedTabPage
    @Published private(set) var departingPages: [FeedTabPage] = []

    let tabs: [FeedTab]

    var tabSelectionPublisher: AnyPublisher<FeedTab, Never> {
        tabSelectionSubject.eraseToAnyPublisher()
    }

    private let tabSelectionSubject = PassthroughSubject<FeedTab, Never>()
    private var sheetSize: ShtorkaSize = .collapsed
    private var slideDirection: CGFloat = 1

    var pages: [FeedTabPage] {
        departingPages + [currentPage]
    }

    init(tabs: [FeedTab]) {
        self.tabs = tabs

        selectedTab = tabs[0]
        currentPage = FeedTabPage(tab: tabs[0])
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

    func startSlide(to tab: FeedTab, target: FeedScrollTarget?) -> FeedScrollTarget? {
        guard currentPage.id != tab.id else {
            return resolve(target)
        }

        slideDirection = index(of: tab) > index(of: currentPage.tab) ? 1 : -1
        let returning = departingPages.first { $0.id == tab.id }
        departingPages = departingPages.filter { $0.id != tab.id } + [currentPage]
        // A lazy list created outside the viewport can stay empty after sliding in.
        // Let new pages realize their visible rows before moving them to the starting edge.
        currentPage = returning ?? FeedTabPage(tab: tab, isPreparing: true)
        return resolve(target)
    }

    func prepareSlide() -> Bool {
        guard currentPage.isPreparing else { return false }

        currentPage.offset = slideDirection
        currentPage.isPreparing = false
        return true
    }

    func slide() {
        currentPage.offset = 0
        for index in departingPages.indices {
            departingPages[index].offset = -slideDirection
        }
    }

    func settleSlide() {
        departingPages = []
        updatePromoBannersVisibility()
    }

    func showInstantly(_ tab: FeedTab, target: FeedScrollTarget?) -> FeedScrollTarget? {
        departingPages = []
        currentPage = FeedTabPage(tab: tab)
        updatePromoBannersVisibility()
        return target
    }

    /// Select the page without animating or touching the scroll; the pager may not be mounted yet.
    private func movePage(to tab: FeedTab) {
        guard currentPage.id != tab.id else {
            return
        }

        departingPages = []
        currentPage = FeedTabPage(tab: tab, topInset: currentPage.topInset)
        updatePromoBannersVisibility()
    }

    private func resolve(_ target: FeedScrollTarget?) -> FeedScrollTarget? {
        switch target {
        case .jump(let anchor, let shift):
            // Restore before the slide in either direction. Compensating the outgoing pages
            // keeps them in place without changing the scroll offset again at completion.
            currentPage.topInset = 0
            for index in departingPages.indices {
                departingPages[index].topInset += shift
            }
            return .jump(anchor: anchor, shift: shift)
        case .pinTabs, .scroll:
            currentPage.topInset = 0
            for index in departingPages.indices {
                departingPages[index].topInset = 0
            }
            return target
        case nil:
            currentPage.topInset = 0
            return nil
        }
    }

    private func index(of tab: FeedTab) -> Int {
        tabs.firstIndex { $0.id == tab.id } ?? 0
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
