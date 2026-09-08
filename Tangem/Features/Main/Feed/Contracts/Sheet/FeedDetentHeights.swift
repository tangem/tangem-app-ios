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
    static let initialCollapsedHeight: CGFloat = 70

    @Published private(set) var detents: ShtorkaDetents

    /// Kept out of `detents`: the sheet height arrives on every drag frame, and a detent set mutated mid-drag makes the sheet jump.
    @Published private(set) var expansionProgress: CGFloat = 0

    private var searchBarHeight = FeedDetentHeights.initialCollapsedHeight
    private var widgetsHeight: CGFloat = .zero
    private var tabChipsHeight: CGFloat = .zero
    private var safeArea = EdgeInsets()

    private var sheetHeight: CGFloat = .zero
    private var fullSheetHeight: CGFloat?

    var detentsPublisher: AnyPublisher<ShtorkaDetents, Never> {
        $detents.eraseToAnyPublisher()
    }

    var expansionProgressPublisher: AnyPublisher<CGFloat, Never> {
        $expansionProgress.removeDuplicates().eraseToAnyPublisher()
    }

    init() {
        detents = ShtorkaDetents(collapsed: .height(Self.initialCollapsedHeight), medium: .height(Self.initialCollapsedHeight))
        syncDetents()
    }

    func report(searchBar height: CGFloat) {
        searchBarHeight = height.roundedToDeviceScale()
        syncDetents()
    }

    func report(widgets height: CGFloat) {
        widgetsHeight = height.roundedToDeviceScale()
        syncDetents()
    }

    func report(tabChips height: CGFloat) {
        tabChipsHeight = height.roundedToDeviceScale()
        syncDetents()
    }

    func report(safeArea insets: EdgeInsets) {
        safeArea = insets
        syncDetents()
    }

    func report(sheetHeight height: CGFloat) {
        sheetHeight = (height + safeArea.bottom).roundedToDeviceScale()
        fullSheetHeight = max(fullSheetHeight ?? sheetHeight, sheetHeight)

        expansionProgress = makeExpansionProgress()
    }
}

// MARK: - Private

private extension FeedDetentHeights {
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

    func makeExpansionProgress() -> CGFloat {
        guard let fullSheetHeight else {
            return 0
        }

        let travel = fullSheetHeight - collapsed
        guard travel > 0 else {
            return 0
        }

        return clamp((sheetHeight - collapsed) / travel, min: 0, max: 1)
    }

    func syncDetents() {
        let updated = ShtorkaDetents(collapsed: .height(collapsed), medium: .height(medium))

        guard updated != detents else {
            return
        }

        detents = updated
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
