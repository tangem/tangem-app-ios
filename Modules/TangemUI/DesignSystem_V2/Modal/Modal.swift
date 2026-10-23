//
//  Modal.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils

struct Modal<Header: View, Content: View>: View {
    private let size: ModalSize
    private let contentLayout: ModalContentLayout
    private let dragIndicator: Visibility
    private let navigation: ModalNavigation?
    private let header: Header
    private let content: Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.dismiss) private var dismiss

    @State private var headerHeight: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    @State private var footerHeight: CGFloat = 0
    @State private var navigationBarHeight: CGFloat = 0
    @State private var isContentScrolled = false
    @State private var isSearchPresented = false
    @State private var isPresentationSettled = false

    init(
        size: ModalSize = .flexible,
        contentLayout: ModalContentLayout = .scrollable,
        dragIndicator: Visibility = .visible,
        navigation: ModalNavigation? = nil,
        @ViewBuilder header: () -> Header = { EmptyView() },
        @ViewBuilder content: () -> Content
    ) {
        self.size = size
        self.contentLayout = contentLayout
        self.dragIndicator = dragIndicator
        self.navigation = navigation
        self.header = header()
        self.content = content()
    }

    var body: some View {
        Group {
            if let navigation {
                NavigationStack {
                    barLayout
                        .environment(\.footerHost, footerHost)
                        .topNavigation(
                            title: navigation.title,
                            subtitle: navigation.subtitle,
                            animatesSubtitleAppearance: !reduceMotion,
                            leading: leadingPolicy(navigation.leading),
                            actions: navigation.actions,
                            onClose: navigation.onClose ?? { dismiss() }
                        )
                }
                .environment(\.topNavigationDrawsBarBackground, false)
            } else {
                layout
                    .environment(\.footerHost, footerHost)
            }
        }
        .modifier(ModalDetentModifier(
            size: isSearchPresented ? .full : size,
            contentLayout: contentLayout,
            height: measuredHeight,
            animatesChanges: isPresentationSettled
        ))
        .animation(heightAnimation, value: idealHeight)
        .onFirstDidAppear { isPresentationSettled = true }
        .presentationCornerRadius(ModalAppearance.cornerRadius)
        .presentationDragIndicator(dragIndicator)
        .modifier(ModalBackgroundModifier(size: size))
        .presentationBackgroundInteraction(.disabled)
    }

    private var layout: some View {
        readingNavigationBarHeight(GeometryReader { geometry in
            let scrollsSheet = contentLayout != .intrinsic
                && headerHeight + Metrics.minContentHeight + footerHeight > geometry.size.height

            // Keep one content tree so keyboard and Dynamic Type changes preserve focus and local state.
            ScrollView(contentLayout == .intrinsic || scrollsSheet ? .vertical : []) {
                VStack(spacing: 0) {
                    headerBlock

                    bodyContent
                        .frame(height: bodyHeight(availableHeight: geometry.size.height, scrollsSheet: scrollsSheet))

                    footerSpace
                }
                .frame(maxWidth: .infinity, alignment: .top)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)
        }
        .overlayPreferenceValue(ModalFooterPreferenceKey.self, alignment: .bottom) { item in
            footerBlock(item)
        })
    }

    /// The scroll view runs right under the navigation bar, so the content scrolls under `barFade`.
    private var barLayout: some View {
        readingNavigationBarHeight(
            VStack(spacing: 0) {
                headerBlock

                barBody

                footerSpace
            }
            .overlayPreferenceValue(ModalFooterPreferenceKey.self, alignment: .bottom) { item in
                footerBlock(item)
            }
            .onPreferenceChange(ModalSearchPresentedPreferenceKey.self) { isSearchPresented = $0 }
        )
        .overlay(alignment: .top) {
            barFade
        }
    }

    @ViewBuilder
    private var barBody: some View {
        switch contentLayout {
        case .scrollable, .intrinsic:
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 0) {
                    content
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)
        case .fill:
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scrollBounceBehavior(.basedOnSize)
                .scrollDismissesKeyboard(.interactively)
        }
    }

    /// Stays on: tinted with the surface color, it blends into the bare surface and only shows over scrolled content.
    private var barFade: some View {
        Fade(position: .top)
            .blurred(!reduceTransparency)
            .backgroundColor(ModalSurface.fill(isExpanded: size == .full, reduceTransparency: reduceTransparency))
            .frame(height: navigationBarHeight)
            .ignoresSafeArea(edges: .top)
    }

    private var headerBlock: some View {
        VStack(spacing: 0) {
            header
        }
        .fixedSize(horizontal: false, vertical: true)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { headerHeight = $0 }
    }

    private var footerSpace: some View {
        Color.clear
            .frame(height: footerHeight)
    }

    private func footerBlock(_ item: ModalFooterItem?) -> some View {
        VStack(spacing: 0) {
            item?.view
        }
        .fixedSize(horizontal: false, vertical: true)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { footerHeight = $0 }
    }

    private var footerHost: FooterHost {
        FooterHost(
            modalSurface: ModalSurface.fill(isExpanded: size == .full, reduceTransparency: reduceTransparency),
            supportsNativeSearch: navigation != nil
        )
    }

    private func readingNavigationBarHeight(_ layout: some View) -> some View {
        layout
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .onGeometryChange(for: CGFloat.self, of: \.safeAreaInsets.top) { topInset in
                if navigation != nil, topInset > 0 {
                    navigationBarHeight = topInset
                }
            }
    }

    @ViewBuilder
    private var bodyContent: some View {
        switch contentLayout {
        case .scrollable:
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    content
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
                .onGeometryChange(for: Bool.self) {
                    $0.frame(in: .named(ModalCoordinateSpace.content)).minY < 0
                } action: { isContentScrolled = $0 }
            }
            .coordinateSpace(name: ModalCoordinateSpace.content)
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)
            .reverseMask(alignment: .top) {
                if isContentScrolled {
                    FeedTopFade()
                }
            }
        case .intrinsic:
            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
            .frame(minHeight: Metrics.minContentHeight, maxHeight: .infinity, alignment: .top)
        case .fill:
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var heightAnimation: Animation? {
        reduceMotion || !isPresentationSettled ? nil : .spring(response: 0.35, dampingFraction: 1)
    }

    private var idealHeight: CGFloat {
        return ceil(navigationBarHeight + headerHeight + max(Metrics.minContentHeight, contentHeight) + footerHeight)
    }

    private var measuredHeight: CGFloat? {
        navigation != nil && navigationBarHeight == 0 ? nil : idealHeight
    }

    private func leadingPolicy(_ policy: TopNavigation.LeadingPolicy) -> TopNavigation.LeadingPolicy {
        switch policy {
        case .automatic: .custom(.back { dismiss() })
        case .custom, .none, .image: policy
        }
    }

    private func bodyHeight(availableHeight: CGFloat, scrollsSheet: Bool) -> CGFloat {
        if contentLayout == .intrinsic {
            // Intrinsic content keeps its natural height while the sheet catches up with content changes.
            let remainingHeight = size == .full ? availableHeight - headerHeight - footerHeight : 0
            return max(Metrics.minContentHeight, contentHeight, remainingHeight)
        }

        if scrollsSheet {
            // A caller-owned scroll view must leave room to drag the outer sheet to its header and footer.
            return max(Metrics.minContentHeight, contentLayout == .fill ? availableHeight / 2 : contentHeight)
        }

        return max(Metrics.minContentHeight, availableHeight - headerHeight - footerHeight)
    }
}

private extension Modal {
    enum Metrics {
        static var minContentHeight: CGFloat { 48 }
    }
}

// MARK: - Content fade

private enum ModalCoordinateSpace {
    static let content = "ModalContent"
}
