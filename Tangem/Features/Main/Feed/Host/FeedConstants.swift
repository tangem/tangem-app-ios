//
//  FeedConstants.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import CoreGraphics

enum FeedConstants {
    static let scrollCoordinateSpace = "FeedView.scroll"
    static let searchContentInset: CGFloat = 16
    static let contentAnchorID = "feedContent"
    static let tabsAnchorID = "feedTabs"
    static let scrollAnchorHeight: CGFloat = 1
    static let widgetsAnchorID = "feedWidgetsRow"
    static let widgetsToTabsSpacing: CGFloat = 16
    static let chipsBottomInset: CGFloat = 24

    static var usesFloatingSheet: Bool {
        if #available(iOS 26.0, *) {
            true
        } else {
            false
        }
    }

    static var collapsedBottomInset: CGFloat {
        usesFloatingSheet ? 0 : 12
    }
}
