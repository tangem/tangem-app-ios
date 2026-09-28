//
//  FeedScrollState.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

final class FeedScrollState {
    private(set) var tabID: String?
    private(set) var offset: CGFloat = 0
    private var offsets: [String: CGFloat] = [:]
    private var pendingOffset: CGFloat?

    func select(tabID: String, headerHeight: CGFloat) {
        guard self.tabID != tabID else { return }

        let currentOffset = pendingOffset ?? offset
        let headerHeight = max(0, headerHeight)
        if let previousID = self.tabID {
            offsets[previousID] = currentOffset
        }

        let savedOffset = offsets[tabID] ?? 0
        pendingOffset = savedOffset > headerHeight ? savedOffset : min(currentOffset, headerHeight)
        self.tabID = tabID
    }

    func pinTabs(headerHeight: CGFloat) {
        pendingOffset = max(pendingOffset ?? offset, max(0, headerHeight))
    }

    func report(offset: CGFloat, tabID: String, widgetsHeight: CGFloat) {
        guard self.tabID == tabID, pendingOffset == nil else { return }

        self.offset = max(0, offset)
        if self.offset < widgetsHeight {
            // Revealing the widgets restarts every tab's list without moving the active scroll view.
            offsets.removeAll()
        }
    }

    func restorationAnchor(tabID: String, viewportHeight: CGFloat) -> UnitPoint? {
        let travel = viewportHeight - FeedConstants.scrollAnchorHeight

        guard self.tabID == tabID, let pendingOffset, travel > 0 else {
            return nil
        }

        offset = pendingOffset
        self.pendingOffset = nil

        // Aligning the fixed top marker above the viewport restores the exact offset regardless of the lazy content's estimated height.
        return UnitPoint(x: 0, y: -offset / travel)
    }

    func reset() {
        offset = 0
        pendingOffset = nil
        offsets.removeAll()
    }
}

enum FeedScrollTarget {
    case pinTabs
    case jump(anchor: UnitPoint, shift: CGFloat)
    case scroll(anchor: UnitPoint)
}
