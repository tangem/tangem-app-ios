//
//  FullPagePagerView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils

/// A full-width pager view that shows adjacent pages during swipe gestures.
/// Unlike `CardsInfoPagerView`, pages occupy the full width at rest with no peek margins.
/// Horizontal swipe only works on the header area; the body content scrolls vertically.
///
/// Optimized for memory efficiency:
/// - **iOS 17+**: Uses native `ScrollView` with `.scrollTargetBehavior(.paging)` for true lazy loading
/// - **iOS 16**: Uses UIKit `UIScrollView` with `isPagingEnabled` and windowed rendering
struct FullPagePagerView<Data, Header, Body>: View
    where Data: RandomAccessCollection,
    Data.Element: Identifiable,
    Data.Index == Int,
    Header: View,
    Body: View {
    typealias HeaderFactory = (Data.Element) -> Header
    typealias BodyFactory = (Data.Element) -> Body

    // MARK: - Dependencies

    private let data: Data
    private let headerFactory: HeaderFactory
    private let bodyFactory: BodyFactory

    // MARK: - State

    @Binding private var selectedIndex: Int

    // MARK: - Configuration

    private var isScrollDisabled: Bool = false
    private var onPageChangeCallback: ((CardsInfoPageChangeReason) -> Void)?

    // MARK: - Initialization

    init(
        data: Data,
        selectedIndex: Binding<Int>,
        @ViewBuilder headerFactory: @escaping HeaderFactory,
        @ViewBuilder bodyFactory: @escaping BodyFactory
    ) {
        self.data = data
        _selectedIndex = selectedIndex
        self.headerFactory = headerFactory
        self.bodyFactory = bodyFactory
    }

    // MARK: - Body

    var body: some View {
        if #available(iOS 17.0, *) {
            FullPagePagerViewModern(
                data: data,
                selectedIndex: $selectedIndex,
                isScrollDisabled: isScrollDisabled,
                onPageChangeCallback: onPageChangeCallback,
                headerFactory: headerFactory,
                bodyFactory: bodyFactory
            )
        } else {
            FullPagePagerViewLegacy(
                data: data,
                selectedIndex: $selectedIndex,
                isScrollDisabled: isScrollDisabled,
                onPageChangeCallback: onPageChangeCallback,
                headerFactory: headerFactory,
                bodyFactory: bodyFactory
            )
        }
    }
}

// MARK: - Setupable

extension FullPagePagerView: Setupable {
    func horizontalScrollDisabled(_ disabled: Bool) -> Self {
        map { $0.isScrollDisabled = disabled }
    }

    func onPageChange(_ callback: @escaping (CardsInfoPageChangeReason) -> Void) -> Self {
        map { $0.onPageChangeCallback = callback }
    }
}
