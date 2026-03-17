//
//  FullPagePagerView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils

/// A full-width pager view that shows adjacent pages during swipe gestures.
/// Unlike `CardsInfoPagerView`, pages occupy the full width at rest with no peek margins.
/// Horizontal swipe only works on the header area; the body content scrolls vertically.
///
/// Optimized for memory efficiency:
/// - **iOS 17+**: Uses native `ScrollView` with `.scrollTargetBehavior(.paging)` for true lazy loading
/// - **iOS 16**: Uses UIKit `UIScrollView` with `isPagingEnabled` and windowed rendering
struct FullPagePagerView<Data, Navigation, Header, Body>: View
    where Data: RandomAccessCollection,
    Data.Element: Identifiable,
    Data.Index == Int,
    Navigation: ViewModifier,
    Header: View,
    Body: View {
    typealias NavigationFactory = (Data.Element) -> Navigation
    typealias HeaderFactory = (Data.Element) -> Header
    typealias BodyFactory = (Data.Element) -> Body

    // MARK: - Dependencies

    private let data: Data
    private let refreshScrollViewStateObject: RefreshScrollViewStateObject
    private let navigationFactory: NavigationFactory
    private let headerFactory: HeaderFactory
    private let bodyFactory: BodyFactory

    // MARK: - State

    @Binding private var selectedIndex: Int
    @State private var viewportHeight: CGFloat = 0

    // MARK: - Configuration

    private var isScrollDisabled: Bool = false
    private var onHeaderHeightRatioChange: ((CGFloat) -> Void)?
    private var onPageChangeCallback: ((CardsInfoPageChangeReason) -> Void)?

    // MARK: - Initialization

    init(
        data: Data,
        refreshScrollViewStateObject: RefreshScrollViewStateObject,
        selectedIndex: Binding<Int>,
        navigationFactory: @escaping NavigationFactory,
        @ViewBuilder headerFactory: @escaping HeaderFactory,
        @ViewBuilder bodyFactory: @escaping BodyFactory
    ) {
        self.data = data
        self.refreshScrollViewStateObject = refreshScrollViewStateObject
        _selectedIndex = selectedIndex
        self.navigationFactory = navigationFactory
        self.headerFactory = headerFactory
        self.bodyFactory = bodyFactory
    }

    // MARK: - Body

    var body: some View {
        RefreshScrollView(
            stateObject: refreshScrollViewStateObject,
            contentSettings: .simpleContent
        ) {
            makePageContent(viewportHeight: viewportHeight)
        }
        .modifier(NavigationModifier(
            data: data,
            selectedIndex: selectedIndex,
            navigationFactory: navigationFactory
        ))
        .readGeometry(\.size.height) { viewportHeight = $0 }
    }
}

// MARK: - Subviews

private extension FullPagePagerView {
    @ViewBuilder
    func makePageContent(viewportHeight: CGFloat) -> some View {
        if #available(iOS 17.0, *) {
            FullPagePagerViewModern(
                data: data,
                selectedIndex: $selectedIndex,
                isScrollDisabled: isScrollDisabled,
                viewportHeight: viewportHeight,
                refreshScrollViewInteractor: refreshScrollViewStateObject.scrollViewInteractor,
                onHeaderHeightRatioChange: onHeaderHeightRatioChange,
                onPageChangeCallback: onPageChangeCallback,
                headerFactory: headerFactory,
                bodyFactory: bodyFactory
            )
        } else {
            FullPagePagerViewLegacy(
                data: data,
                selectedIndex: $selectedIndex,
                isScrollDisabled: isScrollDisabled,
                viewportHeight: viewportHeight,
                refreshScrollViewInteractor: refreshScrollViewStateObject.scrollViewInteractor,
                onHeaderHeightRatioChange: onHeaderHeightRatioChange,
                onPageChangeCallback: onPageChangeCallback,
                headerFactory: headerFactory,
                bodyFactory: bodyFactory
            )
        }
    }
}

// MARK: - Modifiers

private extension FullPagePagerView {
    struct NavigationModifier: ViewModifier
        where Data: RandomAccessCollection,
        Data.Element: Identifiable,
        Data.Index == Int,
        Navigation: ViewModifier {
        typealias NavigationFactory = (Data.Element) -> Navigation

        let data: Data
        let selectedIndex: Int
        let navigationFactory: NavigationFactory

        func body(content: Content) -> some View {
            if let element = data[safe: selectedIndex] {
                content
                    .modifier(navigationFactory(element))
            } else {
                content
            }
        }
    }
}

// MARK: - Setupable

extension FullPagePagerView: Setupable {
    func horizontalScrollDisabled(_ disabled: Bool) -> Self {
        map { $0.isScrollDisabled = disabled }
    }

    func onHeaderHeightRatioChange(_ callback: @escaping (CGFloat) -> Void) -> Self {
        map { $0.onHeaderHeightRatioChange = callback }
    }

    func onPageChange(_ callback: @escaping (CardsInfoPageChangeReason) -> Void) -> Self {
        map { $0.onPageChangeCallback = callback }
    }
}
