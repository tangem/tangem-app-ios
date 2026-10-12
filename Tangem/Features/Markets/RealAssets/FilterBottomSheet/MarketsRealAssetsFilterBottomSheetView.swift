//
//  MarketsRealAssetsFilterBottomSheetView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct MarketsRealAssetsFilterBottomSheetView: View {
    @ObservedObject private var viewModel: MarketsRealAssetsFilterBottomSheetViewModel

    @State private var headerHeight: CGFloat = 0
    @State private var showBottomFade = false
    @State private var frames = ScrollFrames()

    @ScaledMetric private var contentHorizontalPadding: CGFloat = 16
    @ScaledMetric private var contentTopSpacing: CGFloat = 12
    @ScaledMetric private var bottomFadeHeight: CGFloat = 40

    init(viewModel: MarketsRealAssetsFilterBottomSheetViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: .zero) {
            ZStack(alignment: .top) {
                scrollContent
                header
            }

            MarketsRealAssetsFilterFooterView(viewModel: viewModel)
        }
        .background(DesignSystem.Color.bgPrimary)
    }

    private func updateBottomFade() {
        let scrollOffset = frames.viewport.minY - frames.content.minY
        let value = frames.content.height - frames.viewport.height - scrollOffset > 1

        if value != showBottomFade {
            showBottomFade = value
        }
    }
}

private final class ScrollFrames {
    var content: CGRect = .zero
    var viewport: CGRect = .zero
}

// MARK: - Subviews

private extension MarketsRealAssetsFilterBottomSheetView {
    var scrollContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            MarketsRealAssetsFilterContentView(viewModel: viewModel)
                .padding(.horizontal, contentHorizontalPadding)
                .padding(.top, headerHeight + contentTopSpacing)
                .padding(.bottom, contentHorizontalPadding)
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
                colors: [DesignSystem.Color.bgPrimary.opacity(0), DesignSystem.Color.bgPrimary],
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
                Text(Localization.marketsRealAssetsFilterTitle)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
            },
            trailingContent: { closeButton }
        )
        .readGeometry { headerHeight = $0.frame.height }
    }

    var closeButton: some View {
        TangemUI.Button(
            icon: DesignSystem.Icons.Cross.regular20,
            accessibilityLabel: Localization.commonClose,
            action: viewModel.close
        )
        .size(.x9)
        .styleType(.secondary(.default))
        .accessibilityIdentifier(MarketsAccessibilityIdentifiers.marketsRealAssetsFilterCloseButton)
    }
}

// MARK: - Previews

private let previewSectors: [MarketsDTO.Categories.Sector] = [
    .init(id: 1, code: "technology", displayName: "Technology", displayOrder: 0, tokensCount: 48),
    .init(id: 2, code: "financials", displayName: "Financials", displayOrder: 1, tokensCount: 31),
    .init(id: 3, code: "healthcare", displayName: "Healthcare", displayOrder: 2, tokensCount: 22),
    .init(id: 4, code: "consumer", displayName: "Consumer", displayOrder: 3, tokensCount: 17),
    .init(id: 5, code: "communication", displayName: "Communication", displayOrder: 4, tokensCount: 9),
    .init(id: 6, code: "crypto", displayName: "Crypto", displayOrder: 5, tokensCount: 14),
    .init(id: 7, code: "industrials", displayName: "Industrials", displayOrder: 6, tokensCount: 11),
    .init(id: 8, code: "energy", displayName: "Energy", displayOrder: 7, tokensCount: 8),
]

private let previewCategories: [MarketsDTO.Categories.Category] = [
    .init(id: 1, code: "real-world-assets", displayName: "Real Assets", displayOrder: 0, restricted: false, tokensCount: 648, sectors: [], visible: true),
    .init(id: 2, code: "xstocks", displayName: "xStocks", displayOrder: 1, restricted: false, tokensCount: 212, sectors: previewSectors, visible: true),
    .init(id: 3, code: "etfs", displayName: "ETFs", displayOrder: 2, restricted: false, tokensCount: 18, sectors: [], visible: true),
    .init(id: 4, code: "commodities", displayName: "Commodities", displayOrder: 3, restricted: false, tokensCount: 19, sectors: [], visible: true),
    .init(id: 5, code: "bonds", displayName: "Bonds", displayOrder: 4, restricted: false, tokensCount: 8, sectors: [], visible: true),
]

#Preview("xStocks with sectors") {
    MarketsRealAssetsFilterBottomSheetView(
        viewModel: MarketsRealAssetsFilterBottomSheetViewModel(
            input: RealAssetsCategoryFilterInput(
                categories: previewCategories,
                selection: RealAssetsCategorySelection(category: previewCategories[1]),
                defaultSelection: RealAssetsCategorySelection(category: previewCategories[0]),
                onApply: { _ in }
            ),
            onDismiss: {}
        )
    )
}

#Preview("Commodities geo default") {
    MarketsRealAssetsFilterBottomSheetView(
        viewModel: MarketsRealAssetsFilterBottomSheetViewModel(
            input: RealAssetsCategoryFilterInput(
                categories: previewCategories,
                selection: RealAssetsCategorySelection(category: previewCategories[3]),
                defaultSelection: RealAssetsCategorySelection(category: previewCategories[3]),
                onApply: { _ in }
            ),
            onDismiss: {}
        )
    )
    .preferredColorScheme(.dark)
}
