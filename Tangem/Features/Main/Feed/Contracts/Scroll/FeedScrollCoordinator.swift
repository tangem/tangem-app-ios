//
//  FeedScrollCoordinator.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils

/// Where each tab was left and where the tab being switched to has to land. It belongs to the feed rather than
/// to whatever shows it: the same scroll follows the feed into the sheet on the main screen and onto a screen
/// of its own.
final class FeedScrollCoordinator {
    private let state = FeedScrollState()
    private var widgetsHeight: CGFloat = .zero

    /// A zero is the widgets before they have anything to measure, not a header that has gone away — keeping the
    /// last real height is what stops the first tab from being placed against a header of nothing.
    func report(widgets height: CGFloat) {
        guard height > 0 else { return }

        widgetsHeight = height.roundedToDeviceScale()
    }

    func report(offset: CGFloat, tabID: String) {
        state.report(offset: offset, tabID: tabID)
    }

    func scrollTarget(forTab id: String, viewportHeight: CGFloat, pinTabs: Bool, chipsPinned: Bool) -> FeedScrollTarget? {
        let headerHeight = widgetsHeight + FeedConstants.widgetsToTabsSpacing
        let previousOffset = state.offset
        state.select(tabID: id, headerHeight: headerHeight)

        if pinTabs {
            state.pinTabs(headerHeight: headerHeight)
        }

        guard let anchor = state.restorationAnchor(tabID: id, viewportHeight: viewportHeight),
              state.offset != previousOffset else {
            return nil
        }

        if chipsPinned {
            return .jump(anchor: anchor, shift: state.offset - previousOffset)
        }

        // A viewport-relative anchor overshoots while the sheet grows from medium to full.
        if pinTabs, state.offset == headerHeight {
            return .pinTabs
        }

        return .scroll(anchor: anchor)
    }

    func reset() {
        state.reset()
    }
}
