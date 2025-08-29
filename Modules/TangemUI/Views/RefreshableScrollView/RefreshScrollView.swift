//
//  RefreshScrollView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils
import TangemFoundation

// iOS 26: introspect - ok, custom header - ok
// iOS 18: introspect - ok, custom header - ok
// iOS 17: introspect - ok, custom header - ok
// iOS 16: introspect - ok, custom header - ok
// iOS 15: introspect - ok, custom header - ok

public struct RefreshScrollView<Content: View>: View {
    // Init

    @ObservedObject private var stateObject: RefreshScrollViewStateObject
    private let contentSettings: ContentSettings
    private let showsIndicators: Bool
    private let content: () -> Content

    // Internal

    @State private var introspectResponderChainID = UUID()
    private let coordinateSpaceName = UUID()

    public init(
        stateObject: RefreshScrollViewStateObject,
        showsIndicators: Bool = false,
        contentSettings: ContentSettings = .lazyVStack(),
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.stateObject = stateObject
        self.showsIndicators = showsIndicators
        self.contentSettings = contentSettings
        self.content = content
    }

    public var body: some View {
        ZStack(alignment: .top) {
            refreshControl()

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
            content()
                .refreshingPadding(length: stateObject.refreshingPadding)
        case .lazyVStack(let alignment, let spacing, let pinnedViews):
            LazyVStack(alignment: alignment, spacing: spacing, pinnedViews: pinnedViews, content: content)
                .refreshingPadding(length: stateObject.refreshingPadding)
        }
    }

    @ViewBuilder
    func refreshControl() -> some View {
        TangemIconRefreshControl(
            state: stateObject.state,
            settings: stateObject.settings,
            progress: stateObject.progress
        )
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

private struct RefreshControl: View {
    let state: RefreshScrollViewStateObject.RefreshState
    let settings: RefreshScrollViewStateObject.Settings
    let progress: CGFloat

    var body: some View {
        Rectangle()
            .fill(Color.red.opacity(0.5))
            .frame(height: settings.refreshAreaHeight)
            .overlay {
                switch state {
                case .idle:
                    ProgressView(value: progress).padding(.horizontal, 16)
                // TangemRefreshableIcon(progress: progress, isAnimating: false)
                case .refreshing:
                    ProgressView().scaleEffect(2)
                // TangemRefreshableIcon(progress: 1, isAnimating: true)
                case .stillDragging:
                    Text("STOP DRAGGING")
                }
            }
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

import TangemAssets

struct TangemIconRefreshControl: View {
    let state: RefreshScrollViewStateObject.RefreshState
    let settings: RefreshScrollViewStateObject.Settings
    let progress: CGFloat

    @State private var isPulsing: Bool = false

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.red.opacity(0.5))
                .frame(height: settings.refreshAreaHeight)

            switch state {
            case .idle:
                icon
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(Color.black.opacity(0.5))
                            .frame(height: settings.refreshAreaHeight / 2 * (1 - progress))
                    }
            // TangemRefreshableIcon(progress: progress, isAnimating: false)
            case .refreshing:
                icon
                    .scaleEffect(isPulsing ? 1.2 : 1)
                    .animation(.default.repeatForever(), value: isPulsing)
                    .onAppear { isPulsing = true }
                    .onDisappear { isPulsing = true }
            case .stillDragging:
                VStack(spacing: 2) {
                    icon

                    Text("STOP DRAGGING")
                        .font(.footnote)
                }
            }
        }
    }

    var icon: some View {
        Assets.tangemIconMedium.image
            .frame(height: settings.refreshAreaHeight / 2)
    }
}
