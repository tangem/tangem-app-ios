//
//  FeedDetentHeights.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemFoundation
import TangemUI
import TangemUIUtils

final class FeedDetentHeights: ObservableObject {
    private static let initialSearchBarHeight: CGFloat = 60

    @Published private(set) var detents = ShtorkaDetents(
        collapsed: .height(
            FeedDetentHeights.initialSearchBarHeight + FeedConstants.searchContentInset + FeedConstants.collapsedBottomInset
        )
    )

    /// Kept out of `detents`: the sheet height arrives on every drag frame, and a detent set mutated mid-drag makes the sheet jump.
    @Published private(set) var expansionProgress: CGFloat = 0

    @Published private(set) var isContentCollapsed = true

    @Published private(set) var collapsedBottomInset: CGFloat = FeedDetentHeights.initialSearchBarHeight
        + FeedConstants.searchContentInset
        + FeedConstants.collapsedBottomInset

    private var searchBarHeight = FeedDetentHeights.initialSearchBarHeight
    private var widgetsHeight: CGFloat = .zero
    private var tabChipsHeight: CGFloat = .zero
    private var safeArea = EdgeInsets()

    private var sheetHeight: CGFloat = .zero
    private var windowHeight: CGFloat = .zero

    var detentsPublisher: AnyPublisher<ShtorkaDetents, Never> {
        $detents.eraseToAnyPublisher()
    }

    var expansionProgressPublisher: AnyPublisher<CGFloat, Never> {
        $expansionProgress.removeDuplicates().eraseToAnyPublisher()
    }

    func report(searchBar height: CGFloat) {
        guard height > 0 else { return }
        searchBarHeight = height.roundedToDeviceScale()
        syncDetents()
    }

    func report(widgets height: CGFloat) {
        guard height > 0 else { return }
        widgetsHeight = height.roundedToDeviceScale()
        syncDetents()
    }

    func report(tabChips height: CGFloat) {
        guard height > 0 else { return }
        tabChipsHeight = height.roundedToDeviceScale()
        syncDetents()
    }

    func report(safeArea insets: EdgeInsets) {
        safeArea = insets
        syncDetents()
    }

    func report(window height: CGFloat) {
        windowHeight = height.roundedToDeviceScale()
        expansionProgress = makeExpansionProgress()
    }

    func report(sheetHeight height: CGFloat) {
        sheetHeight = height.roundedToDeviceScale()
        updateContentVisibility()

        expansionProgress = makeExpansionProgress()
    }
}

// MARK: - Private

private extension FeedDetentHeights {
    /// The search bar reports its own height; the feed's top inset below it belongs to the same block.
    var searchBlock: CGFloat {
        searchBarHeight + FeedConstants.searchContentInset
    }

    var collapsed: CGFloat {
        searchBlock + FeedConstants.collapsedBottomInset
    }

    var medium: CGFloat {
        let chipsBlock = tabChipsHeight > .zero ? FeedConstants.widgetsToTabsSpacing + tabChipsHeight : .zero

        return searchBlock
            + widgetsHeight
            + chipsBlock
            + FeedConstants.chipsBottomInset
            - safeArea.bottom
    }

    func makeExpansionProgress() -> CGFloat {
        let start = medium + safeArea.bottom
        let travel = windowHeight - safeArea.top - start
        guard windowHeight > 0, travel > 0 else {
            return 0
        }

        // Finish the fill before the top snap, whose outer inset differs between system sheet styles.
        // Selected detents cannot calibrate this range: programmatic expansion selects full before it arrives.
        let value = (sheetHeight - start) / (travel * Constants.surfaceFadeCompletion)
        return clamp(value, min: 0, max: 1)
    }

    func updateContentVisibility() {
        // Two thresholds, so the settling spring cannot flip the content back and forth.
        let margin = isContentCollapsed ? Constants.expandingMargin : Constants.collapsingMargin
        let isCollapsed = sheetHeight <= collapsed + margin
        if isCollapsed != isContentCollapsed {
            isContentCollapsed = isCollapsed
        }
    }

    func syncDetents() {
        updateContentVisibility()
        expansionProgress = makeExpansionProgress()
        // Reserve the collapsed sheet and its floating gap without moving the wallet content during a drag.
        let bottomInset = collapsed + (FeedConstants.usesFloatingSheet ? safeArea.bottom : 0)
        if collapsedBottomInset != bottomInset {
            collapsedBottomInset = bottomInset
        }
        // A collapsed floating sheet sits above the home indicator; an edge-attached one extends through the safe area.
        let collapsedSafeArea = FeedConstants.usesFloatingSheet ? 0 : safeArea.bottom
        let collapsedHeight = max(0, collapsed - collapsedSafeArea)
        // Before content is laid out, subtracting the safe area can put medium below collapsed.
        let mediumDetent: PresentationDetent = widgetsHeight > 0 && medium > collapsedHeight ? .height(medium) : ShtorkaDetents().medium
        let updated = ShtorkaDetents(collapsed: .height(collapsedHeight), medium: mediumDetent)

        guard updated != detents else {
            return
        }

        detents = updated
    }
}

private extension FeedDetentHeights {
    enum Constants {
        static let surfaceFadeCompletion: CGFloat = 0.9
        static let collapsingMargin: CGFloat = 24
        static let expandingMargin: CGFloat = 40
    }
}
