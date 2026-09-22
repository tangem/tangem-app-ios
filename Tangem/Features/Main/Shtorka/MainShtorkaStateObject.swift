//
//  MainShtorkaStateObject.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemFoundation
import TangemUI

/// The sizes the feed measures for the sheet and the scroll anchor it asks back. Only the top of the feed reports:
/// the views below it hand their measurements up instead of knowing about the sheet.
protocol MainShtorkaReporting: AnyObject {
    func report(searchBar height: CGFloat)
    func report(widgets height: CGFloat)
    func report(tabChips height: CGFloat)
    func report(scrollOffset: CGFloat, tabID: String)
    func scrollTarget(forTab id: String, viewportHeight: CGFloat, pinTabs: Bool, chipsPinned: Bool) -> FeedScrollTarget?
}

/// What a view inside the sheet may do with it: follow the size it settles on and open it. The presentation state
/// stays out of reach.
protocol MainShtorkaViewActionProvider: AnyObject {
    var sizePublisher: AnyPublisher<ShtorkaSize, Never> { get }

    func expand()
}

final class MainShtorkaStateObject: ObservableObject {
    @Injected(\.mainBottomSheetUIManager) private var bottomSheetUIManager: MainBottomSheetUIManager

    @Published var isPresented = false
    @Published var size: ShtorkaSize = .collapsed {
        didSet {
            if size != .full {
                scrollState.reset()
            }
        }
    }

    @Published private(set) var isContentCollapsed = true

    @Published private var feedDetents = ShtorkaDetents()
    @Published private var isNavigationActive = false

    var detents: ShtorkaDetents {
        guard isNavigationActive else { return feedDetents }

        // The detent set deduplicates collapsed, and its reverse mapping still resolves to collapsed.
        return ShtorkaDetents(collapsed: feedDetents.collapsed, medium: feedDetents.collapsed, full: feedDetents.full)
    }

    var expansionProgressPublisher: AnyPublisher<CGFloat, Never> {
        heights.expansionProgressPublisher
    }

    private let heights = FeedDetentHeights()
    private let scrollState = FeedScrollState()
    private var bag = Set<AnyCancellable>()

    init() {
        heights.detentsPublisher.assign(to: &$feedDetents)
        heights.$isContentCollapsed.assign(to: &$isContentCollapsed)

        bind()
    }

    func collapse() {
        size = .collapsed
    }

    func expand() {
        size = .full
    }

    func setNavigationActive(_ isActive: Bool) {
        if isActive {
            expand()
        }
        isNavigationActive = isActive
    }

    // MARK: - Tab scroll positions

    func report(scrollOffset: CGFloat, tabID: String) {
        scrollState.report(offset: scrollOffset, tabID: tabID)
    }

    func scrollTarget(forTab id: String, viewportHeight: CGFloat, pinTabs: Bool, chipsPinned: Bool) -> FeedScrollTarget? {
        let headerHeight = heights.widgetsHeight + FeedConstants.widgetsToTabsSpacing
        let previousOffset = scrollState.offset
        scrollState.select(tabID: id, headerHeight: headerHeight)

        if pinTabs {
            scrollState.pinTabs(headerHeight: headerHeight)
        }

        guard let anchor = scrollState.restorationAnchor(tabID: id, viewportHeight: viewportHeight),
              scrollState.offset != previousOffset else {
            return nil
        }

        if chipsPinned {
            return .jump(anchor: anchor, shift: scrollState.offset - previousOffset)
        }

        return .scroll(anchor: anchor)
    }

    // MARK: - Detent heights

    func report(searchBar height: CGFloat) {
        heights.report(searchBar: height)
    }

    func report(widgets height: CGFloat) {
        heights.report(widgets: height)
    }

    func report(tabChips height: CGFloat) {
        heights.report(tabChips: height)
    }

    func report(safeArea insets: EdgeInsets) {
        heights.report(safeArea: insets)
    }

    func report(window height: CGFloat) {
        heights.report(window: height)
    }

    func report(sheetHeight height: CGFloat) {
        heights.report(sheetHeight: height)
    }
}

// MARK: - Visibility

private extension MainShtorkaStateObject {
    func bind() {
        bottomSheetUIManager
            .isShownPublisher
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { stateObject, isShown in
                isShown ? stateObject.present() : stateObject.hide()
            }
            .store(in: &bag)

        $size
            .map { $0 != .collapsed }
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { stateObject, isExpanded in
                stateObject.bottomSheetUIManager.setExpanded(isExpanded)
            }
            .store(in: &bag)
    }

    func present() {
        guard !isPresented else {
            return
        }

        withTransaction(.withoutAnimations()) {
            isPresented = true
        }
    }

    func hide() {
        guard isPresented else {
            return
        }

        // Instant on purpose: the sheet is normally taken away by a push transition, and an animated dismissal
        // would argue with it.
        withTransaction(.withoutAnimations()) {
            isPresented = false
            collapse()
        }

        heights.report(sheetHeight: .zero)
    }
}

// MARK: - MainShtorkaReporting

extension MainShtorkaStateObject: MainShtorkaReporting {}

// MARK: - MainShtorkaViewActionProvider

extension MainShtorkaStateObject: MainShtorkaViewActionProvider {
    var sizePublisher: AnyPublisher<ShtorkaSize, Never> {
        $size.removeDuplicates().eraseToAnyPublisher()
    }
}
