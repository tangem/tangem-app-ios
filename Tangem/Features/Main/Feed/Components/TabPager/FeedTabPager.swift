//
//  FeedTabPager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import CoreGraphics

final class FeedTabPager<Tab: Identifiable>: ObservableObject {
    @Published private(set) var currentPage: FeedTabPage<Tab>
    @Published private(set) var departingPages: [FeedTabPage<Tab>] = []

    var pages: [FeedTabPage<Tab>] {
        departingPages + [currentPage]
    }

    private let tabs: [Tab]
    private var slideDirection: CGFloat = 1

    init(tabs: [Tab], selectedTab: Tab) {
        self.tabs = tabs

        currentPage = FeedTabPage(tab: selectedTab)
    }

    // MARK: - Switching

    func startSlide(to tab: Tab) {
        guard currentPage.id != tab.id else {
            return
        }

        slideDirection = index(of: tab) > index(of: currentPage.tab) ? 1 : -1
        let returning = departingPages.first { $0.id == tab.id }
        departingPages = departingPages.filter { $0.id != tab.id } + [currentPage]
        // A lazy list created outside the viewport can stay empty after sliding in.
        // Let new pages realize their visible rows before moving them to the starting edge.
        currentPage = returning ?? FeedTabPage(tab: tab, isPreparing: true)
    }

    func prepareSlide() -> Bool {
        guard currentPage.isPreparing else { return false }

        currentPage.offset = slideDirection
        currentPage.isPreparing = false
        return true
    }

    func slide() {
        currentPage.offset = 0
        for index in departingPages.indices where departingPages[index].offset == 0 {
            departingPages[index].offset = -slideDirection
        }
    }

    func settleSlide() {
        departingPages = []
    }

    func show(_ tab: Tab, topInset: CGFloat = 0) {
        departingPages = []
        currentPage = FeedTabPage(tab: tab, topInset: topInset)
    }

    // MARK: - Insets

    func resetCurrentInset() {
        currentPage.topInset = 0
    }

    func resetInsets() {
        currentPage.topInset = 0
        for index in departingPages.indices {
            departingPages[index].topInset = 0
        }
    }

    func shiftDepartingInsets(by shift: CGFloat) {
        for index in departingPages.indices {
            departingPages[index].topInset += shift
        }
    }
}

// MARK: - Private

private extension FeedTabPager {
    func index(of tab: Tab) -> Int {
        tabs.firstIndex { $0.id == tab.id } ?? 0
    }
}
