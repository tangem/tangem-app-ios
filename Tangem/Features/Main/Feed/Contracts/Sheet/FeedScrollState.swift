//
//  FeedScrollState.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation

final class FeedScrollState {
    private(set) var tabID: String?
    private(set) var offset: CGFloat = 0
    private var offsets: [String: CGFloat] = [:]
    private var pendingOffset: CGFloat?

    func select(tabID: String, headerHeight: CGFloat) {
        guard self.tabID != tabID else { return }

        if let previousID = self.tabID {
            offsets[previousID] = pendingOffset ?? offset
        }

        pendingOffset = offsets[tabID] ?? min(offset, max(0, headerHeight))
        self.tabID = tabID
    }

    func pinTabs(headerHeight: CGFloat) {
        pendingOffset = clamp(pendingOffset ?? offset, min: max(0, headerHeight), max: .infinity)
    }

    func report(offset: CGFloat, tabID: String) {
        guard self.tabID == tabID, pendingOffset == nil else { return }
        self.offset = max(0, offset)
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
        if let tabID { offsets[tabID] = 0 }
    }
}

enum FeedScrollTarget {
    case jump(anchor: UnitPoint, shift: CGFloat)
    case scroll(anchor: UnitPoint)
}
