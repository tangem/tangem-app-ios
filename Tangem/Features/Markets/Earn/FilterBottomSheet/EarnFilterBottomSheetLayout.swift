//
//  EarnFilterBottomSheetLayout.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

/// Shared layout for the Earn filter bottom sheets: a blurred navigation header the content scrolls
/// under, a scoped bottom blur above the pinned Cancel button, and the Cancel button itself.
struct EarnFilterBottomSheetLayout<Content: View>: View {
    private let title: String
    private let onClose: () -> Void
    private let onCancel: () -> Void
    private let content: Content

    @State private var headerHeight: CGFloat = 0
    @State private var showBottomFade = false
    @State private var frames = ScrollFrames()

    @ScaledMetric private var contentHorizontalPadding: CGFloat = .unit(.x4)
    @ScaledMetric private var contentTopSpacing: CGFloat = .unit(.x4)
    @ScaledMetric private var cancelPadding: CGFloat = .unit(.x4)
    @ScaledMetric private var bottomFadeHeight: CGFloat = .unit(.x10)

    init(
        title: String,
        onClose: @escaping () -> Void,
        onCancel: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.onClose = onClose
        self.onCancel = onCancel
        self.content = content()
    }

    var body: some View {
        VStack(spacing: .zero) {
            ZStack(alignment: .top) {
                scrollContent
                header
            }

            cancelButton
                .padding(cancelPadding)
        }
        .background(Color.Tangem.Surface.level2)
    }

    private func updateBottomFade() {
        let scrollOffset = frames.viewport.minY - frames.content.minY
        let value = frames.content.height - frames.viewport.height - scrollOffset > 1

        if value != showBottomFade {
            showBottomFade = value
        }
    }
}

/// Reference box so per-frame geometry updates don't invalidate the view body — only `showBottomFade` flips do.
private final class ScrollFrames {
    var content: CGRect = .zero
    var viewport: CGRect = .zero
}

// MARK: - Subviews

private extension EarnFilterBottomSheetLayout {
    var scrollContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            content
                .padding(.horizontal, contentHorizontalPadding)
                .padding(.top, headerHeight + contentTopSpacing)
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: {
                    frames.content = $0
                    updateBottomFade()
                }
        }
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: {
            frames.viewport = $0
            updateBottomFade()
        }
        .overlay(alignment: .bottom) {
            LinearGradient(
                colors: [Color.Tangem.Surface.level2.opacity(0), Color.Tangem.Surface.level2],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: bottomFadeHeight)
            .allowsHitTesting(false)
            .opacity(showBottomFade ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: showBottomFade)
        }
    }

    var header: some View {
        NavigationHeader(
            leadingContent: { EmptyView() },
            principalContent: {
                Text(title)
                    .style(Font.Tangem.Heading17.semibold, color: .Tangem.Text.Neutral.primary)
            },
            trailingContent: { closeButton }
        )
        .readGeometry { headerHeight = $0.frame.height }
    }

    var closeButton: some View {
        TangemButton(
            content: .icon(Assets.Glyphs.cross20ButtonNew),
            action: onClose
        )
        .setStyleType(.secondary)
        .setCornerStyle(.rounded)
        .setSize(.x9)
    }

    var cancelButton: some View {
        TangemButton(
            content: .text(AttributedString(Localization.commonCancel)),
            action: onCancel
        )
        .setStyleType(.secondary)
        .setCornerStyle(.rounded)
        .setHorizontalLayout(.infinity)
        .setSize(.x12)
    }
}
