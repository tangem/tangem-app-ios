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
struct FullPagePagerView<Data, Navigation, Header, Body, BottomOverlay>: View
    where Data: RandomAccessCollection,
    Data.Element: Identifiable,
    Data.Index == Int,
    Navigation: ViewModifier,
    Header: View,
    Body: View,
    BottomOverlay: View {
    typealias NavigationFactory = (Data.Element) -> Navigation
    typealias HeaderFactory = (Data.Element) -> Header
    typealias BodyFactory = (Data.Element) -> Body
    typealias BottomOverlayFactory = (Data.Element) -> BottomOverlay

    // MARK: - Dependencies

    private let data: Data
    private let refreshScrollViewStateObject: RefreshScrollViewStateObject
    private let navigationFactory: NavigationFactory
    private let headerFactory: HeaderFactory
    private let bodyFactory: BodyFactory
    private let bottomOverlayFactory: BottomOverlayFactory

    // MARK: - State

    @Binding private var selectedIndex: Int
    @Binding private var headerHeightRatio: CGFloat
    @State private var viewportHeight: CGFloat = 0

    // MARK: - Configuration

    private var isScrollDisabled: Bool = false
    private var onPageChangeCallback: ((CardsInfoPageChangeReason) -> Void)?

    // MARK: - Initialization

    init(
        data: Data,
        refreshScrollViewStateObject: RefreshScrollViewStateObject,
        selectedIndex: Binding<Int>,
        headerHeightRatio: Binding<CGFloat>,
        navigationFactory: @escaping NavigationFactory,
        @ViewBuilder headerFactory: @escaping HeaderFactory,
        @ViewBuilder bodyFactory: @escaping BodyFactory,
        @ViewBuilder bottomOverlayFactory: @escaping BottomOverlayFactory
    ) {
        self.data = data
        self.refreshScrollViewStateObject = refreshScrollViewStateObject
        _selectedIndex = selectedIndex
        _headerHeightRatio = headerHeightRatio
        self.navigationFactory = navigationFactory
        self.headerFactory = headerFactory
        self.bodyFactory = bodyFactory
        self.bottomOverlayFactory = bottomOverlayFactory
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            makeScrollView()
            makeBottomOverlay()
        }
        .ignoresSafeArea(edges: .bottom)
        .modifier(NavigationModifier(
            data: data,
            selectedIndex: selectedIndex,
            navigationFactory: navigationFactory
        ))
        .readGeometry(\.size.height) { viewportHeight = $0 }
    }
}

// MARK: - View makers

private extension FullPagePagerView {
    func makeScrollView() -> some View {
        RefreshScrollView(
            stateObject: refreshScrollViewStateObject,
            contentSettings: .simpleContent,
            content: makePageContent,
        )
    }

    @ViewBuilder
    func makePageContent() -> some View {
        if #available(iOS 17.0, *) {
            FullPagePagerViewModern(
                data: data,
                selectedIndex: $selectedIndex,
                headerHeightRatio: $headerHeightRatio,
                isScrollDisabled: isScrollDisabled,
                viewportHeight: viewportHeight,
                refreshScrollViewInteractor: refreshScrollViewStateObject.scrollViewInteractor,
                onPageChangeCallback: onPageChangeCallback,
                headerFactory: headerFactory,
                bodyFactory: bodyFactory
            )
        } else {
            FullPagePagerViewLegacy(
                data: data,
                selectedIndex: $selectedIndex,
                headerHeightRatio: $headerHeightRatio,
                isScrollDisabled: isScrollDisabled,
                viewportHeight: viewportHeight,
                refreshScrollViewInteractor: refreshScrollViewStateObject.scrollViewInteractor,
                onPageChangeCallback: onPageChangeCallback,
                headerFactory: headerFactory,
                bodyFactory: bodyFactory
            )
        }
    }

    @ViewBuilder
    func makeBottomOverlay() -> some View {
        if let element = data[safe: selectedIndex] {
            bottomOverlayFactory(element)
        }
    }
}

// MARK: - Subviews

private extension FullPagePagerView {
    struct NavigationModifier: ViewModifier {
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

    func onPageChange(_ callback: @escaping (CardsInfoPageChangeReason) -> Void) -> Self {
        map { $0.onPageChangeCallback = callback }
    }
}
