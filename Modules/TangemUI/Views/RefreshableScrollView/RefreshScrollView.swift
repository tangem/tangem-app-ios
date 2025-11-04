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
    // Init

    @ObservedObject
    private var stateObject: RefreshScrollViewStateObject
    private let contentSettings: ContentSettings
    private let showsIndicators: Bool
    private let content: () -> Content

    // Internal

    @State private var introspectResponderChainID = UUID()

    // Setupable

    private var contentOffset: Binding<CGPoint>?

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
            CustomRefreshControl(stateObject: stateObject.refreshControlStateObject)

            EnhanceScrollView(.vertical, showsIndicators: showsIndicators) {
                scrollContent
            }
            .readContentOffset(
                contentOffset: .init(
                    get: { stateObject.contentOffset },
                    set: { newValue in
                        stateObject.contentOffset = newValue
                        contentOffset?.wrappedValue = newValue
                    }
                )
            )
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

// MARK: - Setupable

extension RefreshScrollView: Setupable {
    public func readContentOffset(contentOffset: Binding<CGPoint>) -> Self {
        map { $0.contentOffset = contentOffset }
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
