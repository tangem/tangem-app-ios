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
    private var pendingJump: PendingJump?

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
        currentPage = returning ?? FeedTabPage(tab: tab, offset: slideDirection)
        return resolve(target)
    }

    func slide() {
        currentPage.offset = 0
        for index in departingPages.indices {
            departingPages[index].offset = -slideDirection
        }
    }

    func settleSlide() -> FeedScrollTarget? {
        departingPages = []
        updatePromoBannersVisibility()
        return finishPendingJump()
    }

    func showInstantly(_ tab: FeedTab, target: FeedScrollTarget?) -> FeedScrollTarget? {
        let pending = finishPendingJump()
        departingPages = []
        currentPage = FeedTabPage(tab: tab)
        updatePromoBannersVisibility()
        return target ?? pending
    }

    private func resolve(_ target: FeedScrollTarget?) -> FeedScrollTarget? {
        switch target {
        case .jump(let anchor, let shift):
            let actualShift = (pendingJump?.shift ?? 0) + shift
            guard actualShift >= 0 else {
                pendingJump = PendingJump(anchor: anchor, shift: actualShift)
                currentPage.topInset = -actualShift
                return nil
            }

            pendingJump = nil
            currentPage.topInset = 0
            for index in departingPages.indices {
                departingPages[index].topInset += actualShift
            }
            return .jump(anchor: anchor, shift: actualShift)
        case .pinTabs, .scroll:
            pendingJump = nil
            currentPage.topInset = 0
            for index in departingPages.indices {
                departingPages[index].topInset = 0
            }
            return target
        case nil:
            currentPage.topInset = -(pendingJump?.shift ?? 0)
            return nil
        }
    }

    private func finishPendingJump() -> FeedScrollTarget? {
        guard let jump = pendingJump else { return nil }

        pendingJump = nil
        currentPage.topInset = 0
        return .jump(anchor: jump.anchor, shift: jump.shift)
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

private struct PendingJump {
    let anchor: UnitPoint
    let shift: CGFloat
}
