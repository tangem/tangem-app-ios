//
//  RefreshScrollView.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils
import TangemFoundation

public struct RefreshScrollView<Content: View>: View {
    @ObservedObject private var stateObject: RefreshScrollViewStateObject
    private let contentSettings: ContentSettings
    private let showsIndicators: Bool
    private let content: Content

    @State private var introspectResponderChainID = UUID()
    private let coordinateSpaceName = UUID()

    public init(
        stateObject: RefreshScrollViewStateObject,
        showsIndicators: Bool = false,
        contentSettings: ContentSettings = .lazyVStack(),
        @ViewBuilder content: () -> Content
    ) {
        self.stateObject = stateObject
        self.showsIndicators = showsIndicators
        self.contentSettings = contentSettings
        self.content = content()
    }

    public var body: some View {
        ZStack(alignment: .top) {
            CustomRefreshControl(stateObject: stateObject.refreshControlStateObject)

            if #available(iOS 18.0, *) {
                scrollView
            } else {
                legacyScrollView
            }
        }
        .introspectResponderChain(
            introspectedType: UIScrollView.self,
            includeSubviews: true,
            updateOnChangeOf: introspectResponderChainID,
            action: { scrollView in
                stateObject.scrollViewDelegate.set(scrollView: scrollView)
            }
        )
        .onAppear {
            introspectResponderChainID = .init()
        }
    }

    @available(iOS 18.0, *)
    var scrollView: some View {
        ScrollView(.vertical) {
            scrollContent
        }
        .scrollIndicators(showsIndicators ? .automatic : .hidden)
        .onScrollGeometryChange(for: ScrollGeometry.self, of: \.self) { _, newValue in
            let yOffset = newValue.contentOffset.y + newValue.contentInsets.top

            stateObject.contentOffset = .init(x: newValue.contentOffset.x, y: yOffset)
        }
    }

    var legacyScrollView: some View {
        ScrollView(.vertical, showsIndicators: showsIndicators) {
            scrollContent.readContentOffset(
                inCoordinateSpace: .named(coordinateSpaceName),
                bindTo: $stateObject.contentOffset
            )
        }
        .coordinateSpace(name: coordinateSpaceName)
    }

    @ViewBuilder
    var scrollContent: some View {
        switch contentSettings {
        case .simpleContent:
            content
                .refreshingPadding(length: stateObject.refreshingPadding)

        case .lazyVStack(let alignment, let spacing, let pinnedViews):
            LazyVStack(alignment: alignment, spacing: spacing, pinnedViews: pinnedViews, content: { content })
                .refreshingPadding(length: stateObject.refreshingPadding)
        }
    }
}

public extension RefreshScrollView {
    enum ContentSettings {
        case simpleContent
        case lazyVStack(
            alignment: HorizontalAlignment = .center,
            spacing: CGFloat? = nil,
            pinnedViews: PinnedScrollableViews = .init()
        )
    }
}

private extension View {
    /**
     We have a few options:
     - `offset(y: stateObject.contentOffset)`is not fitted because when refresh is ended the whole connect is moving up
     - `safeAreaPadding(.top, stateObject.contentOffset)` semantically better to use. It's like imitation `UIScrollView.contentInset.top`
     - `.padding(.top, stateObject.contentOffset)` - fallback to previous iOS versions.
     */
    @ViewBuilder
    func refreshingPadding(length: CGFloat) -> some View {
        if #available(iOS 17.0, *) {
            safeAreaPadding(.top, length)
        } else {
            padding(.top, length)
        }
    }
}
