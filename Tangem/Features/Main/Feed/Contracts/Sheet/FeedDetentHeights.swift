//
//  FeedDetentHeights.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation
import TangemUIUtils

struct FeedDetentHeights: Equatable {
    static let initialCollapsedHeight: CGFloat = 70

    private var searchBarHeight: CGFloat = initialCollapsedHeight

    // TEMP: Until real sheet content
    private var widgetsHeight: CGFloat = 300
    private var tabChipsHeight: CGFloat = 80
    private var safeArea = EdgeInsets()
    private var sheetHeight: CGFloat = .zero
    private var fullSheetHeight: CGFloat?

    init() {}

    var collapsed: CGFloat {
        searchBarHeight
    }

    var medium: CGFloat {
        let chipsBlock = tabChipsHeight > .zero ? Constants.widgetsToChipsSpacing + tabChipsHeight : .zero

        return searchBarHeight
            + Constants.searchToWidgetsSpacing
            + widgetsHeight
            + chipsBlock
            + Constants.bottomInset
            - safeArea.bottom
    }

    var expansionProgress: CGFloat {
        guard let fullSheetHeight else {
            return 0
        }

        let travel = fullSheetHeight - collapsed
        guard travel > 0 else {
            return 0
        }

        return clamp((sheetHeight - collapsed) / travel, min: 0, max: 1)
    }

    mutating func report(searchBar height: CGFloat) {
        searchBarHeight = height.roundedToDeviceScale()
    }

    mutating func report(widgets height: CGFloat) {
        widgetsHeight = height.roundedToDeviceScale()
    }

    mutating func report(tabChips height: CGFloat) {
        tabChipsHeight = height.roundedToDeviceScale()
    }

    mutating func report(safeArea insets: EdgeInsets) {
        safeArea = insets
    }

    mutating func report(sheetHeight height: CGFloat) {
        sheetHeight = (height + safeArea.bottom).roundedToDeviceScale()
        fullSheetHeight = max(fullSheetHeight ?? sheetHeight, sheetHeight)
    }
}

// MARK: - Constants

private extension FeedDetentHeights {
    enum Constants {
        static let searchToWidgetsSpacing: CGFloat = 12
        static let widgetsToChipsSpacing: CGFloat = 20
        static let bottomInset: CGFloat = 20
    }
}
