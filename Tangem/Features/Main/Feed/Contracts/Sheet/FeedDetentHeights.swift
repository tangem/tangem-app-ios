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
    private var windowHeight: CGFloat = .zero

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

    func syncDetents() {
        let mediumDetent: PresentationDetent = widgetsHeight > 0 ? .height(max(collapsed, medium)) : ShtorkaDetents().medium
        let updated = ShtorkaDetents(collapsed: .height(collapsed), medium: mediumDetent)
        expansionProgress = makeExpansionProgress()

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
        static let surfaceFadeCompletion: CGFloat = 0.9
    }
}
