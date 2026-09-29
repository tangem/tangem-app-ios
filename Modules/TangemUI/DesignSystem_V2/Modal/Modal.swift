//
//  Modal.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct Modal<Header: View, Content: View, Footer: View>: View {
    private let size: ModalSize
    private let contentLayout: ModalContentLayout
    private let navigation: ModalNavigation?
    private let header: Header
    private let content: Content
    private let footer: Footer

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss

    @State private var headerHeight: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    @State private var footerHeight: CGFloat = 0
    @State private var navigationBarHeight: CGFloat = 0

    init(
        size: ModalSize = .flexible,
        contentLayout: ModalContentLayout = .scrollable,
        navigation: ModalNavigation? = nil,
        @ViewBuilder header: () -> Header = { EmptyView() },
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer = { EmptyView() }
    ) {
        self.size = size
        self.contentLayout = contentLayout
        self.navigation = navigation
        self.header = header()
        self.content = content()
        self.footer = footer()
    }

    var body: some View {
        Group {
            if let navigation {
                NavigationStack {
                    layout
                        .topNavigation(
                            title: navigation.title,
                            subtitle: navigation.subtitle,
                            animatesSubtitleAppearance: !reduceMotion,
                            leading: leadingPolicy(navigation.leading),
                            actions: navigation.actions,
                            onClose: navigation.onClose ?? { dismiss() }
                        )
                }
            } else {
                layout
            }
        }
        .modifier(ModalDetentModifier(size: size, contentLayout: contentLayout, height: measuredHeight))
        .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 1), value: idealHeight)
        .presentationCornerRadius(cornerRadius)
        .presentationDragIndicator(.visible)
        .modifier(ModalBackgroundModifier(size: size))
        .presentationBackgroundInteraction(.disabled)
    }

    private var layout: some View {
        GeometryReader { geometry in
            let scrollsSheet = contentLayout != .intrinsic && headerHeight + 48 + footerHeight > geometry.size.height

            // Keep one content tree so keyboard and Dynamic Type changes preserve focus and local state.
            ScrollView(contentLayout == .intrinsic || scrollsSheet ? .vertical : []) {
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        header
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { headerHeight = $0 }

                    bodyContent
                        .frame(height: bodyHeight(availableHeight: geometry.size.height, scrollsSheet: scrollsSheet))

                    VStack(spacing: 0) {
                        footer
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { footerHeight = $0 }
                }
                .frame(maxWidth: .infinity, alignment: .top)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)
        }
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
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)
        case .intrinsic:
            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
            .frame(minHeight: 48, maxHeight: .infinity, alignment: .top)
        case .fill:
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var idealHeight: CGFloat {
        return ceil(navigationBarHeight + headerHeight + max(48, contentHeight) + footerHeight)
    }

    private var measuredHeight: CGFloat? {
        navigation != nil && navigationBarHeight == 0 ? nil : idealHeight
    }

    private func leadingPolicy(_ policy: TopNavigation.LeadingPolicy) -> TopNavigation.LeadingPolicy {
        switch policy {
        case .automatic: .custom(.back { dismiss() })
        case .custom, .none: policy
        }
    }

    private func bodyHeight(availableHeight: CGFloat, scrollsSheet: Bool) -> CGFloat {
        if contentLayout == .intrinsic {
            // Intrinsic content keeps its natural height while the sheet catches up with content changes.
            let remainingHeight = size == .full ? availableHeight - headerHeight - footerHeight : 0
            return max(48, contentHeight, remainingHeight)
        }

        if scrollsSheet {
            // A caller-owned scroll view must leave room to drag the outer sheet to its header and footer.
            return max(48, contentLayout == .fill ? availableHeight / 2 : contentHeight)
        }

        return max(48, availableHeight - headerHeight - footerHeight)
    }

    private var cornerRadius: CGFloat? {
        if #available(iOS 26.0, *) {
            nil
        } else {
            36
        }
    }
}
