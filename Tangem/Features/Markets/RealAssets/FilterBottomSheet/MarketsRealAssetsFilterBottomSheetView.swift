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
    @ScaledMetric private var footerPadding: CGFloat = 16
    @ScaledMetric private var footerButtonSpacing: CGFloat = 8
    @ScaledMetric private var bottomFadeHeight: CGFloat = 40
    @ScaledMetric private var sectionTitleVerticalPadding: CGFloat = 8
    @ScaledMetric private var sectionSpacing: CGFloat = 24
    @ScaledMetric private var rowVerticalPadding: CGFloat = 18
    @ScaledMetric private var rowCounterSpacing: CGFloat = 12
    @ScaledMetric private var radioIconSide: CGFloat = 20
    @ScaledMetric private var chipSpacing: CGFloat = 4
    @ScaledMetric private var chipsTopPadding: CGFloat = 8
    @ScaledMetric private var chipHorizontalPadding: CGFloat = 12
    @ScaledMetric private var chipVerticalPadding: CGFloat = 8

    init(viewModel: MarketsRealAssetsFilterBottomSheetViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: .zero) {
            ZStack(alignment: .top) {
                scrollContent
                header
            }

            footer
                .padding(footerPadding)
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

    var content: some View {
        VStack(alignment: .leading, spacing: .zero) {
            sectionTitle(Localization.commonType)

            ForEach(viewModel.categories) { category in
                categoryRow(category)
            }

            if !viewModel.sectorChipItems.isEmpty {
                sectionTitle(Localization.marketsRealAssetsFilterSectorsTitle)
                    .padding(.top, sectionSpacing)

                sectorChips
                    .padding(.top, chipsTopPadding)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeInOut(duration: 0.2), value: viewModel.selectedCategoryID)
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

    func sectionTitle(_ title: String) -> some View {
        Text(title)
            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            .padding(.vertical, sectionTitleVerticalPadding)
    }

    func categoryRow(_ category: MarketsDTO.Categories.Category) -> some View {
        let isSelected = viewModel.isSelected(category: category)

        return SwiftUI.Button(action: { viewModel.select(category: category) }) {
            HStack(spacing: rowCounterSpacing) {
                Text(MarketsCategoryLocalizer.title(for: category))
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                    .lineLimit(1)

                Spacer(minLength: .zero)

                Text(Localization.commonAssetsCount(category.tokensCount))
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)

                radioIcon(isSelected: isSelected)
            }
            .padding(.vertical, rowVerticalPadding)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(MarketsAccessibilityIdentifiers.marketsRealAssetsFilterCategoryOption(category.code))
    }

    func radioIcon(isSelected: Bool) -> some View {
        Group {
            if isSelected {
                Assets.checkmark20.image
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(DesignSystem.Color.iconStaticDark)
                    .background(DesignSystem.Color.iconAccentBlue, in: .circle)
            } else {
                Assets.circleOutline20.image
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(DesignSystem.Color.borderTertiary)
            }
        }
        .frame(width: radioIconSide, height: radioIconSide)
    }

    var sectorChips: some View {
        HorizontalFlowLayout(
            items: viewModel.sectorChipItems,
            alignment: .leading,
            horizontalSpacing: chipSpacing,
            verticalSpacing: chipSpacing
        ) { item in
            sectorChip(item)
        }
    }

    func sectorChip(_ item: MarketsRealAssetsFilterBottomSheetViewModel.SectorChipItem) -> some View {
        let isSelected = viewModel.isSelected(sectorID: item.sectorID)

        return SwiftUI.Button(action: { viewModel.select(sectorID: item.sectorID) }) {
            Text(item.title)
                .style(
                    DesignSystem.Font.subheadingMediumToken,
                    color: isSelected ? DesignSystem.Color.textInversePrimary : DesignSystem.Color.textPrimary
                )
                .lineLimit(1)
                .padding(.horizontal, chipHorizontalPadding)
                .padding(.vertical, chipVerticalPadding)
                .background(
                    isSelected ? DesignSystem.Color.bgInverse : DesignSystem.Color.bgTransparentPrimary,
                    in: .capsule
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(MarketsAccessibilityIdentifiers.marketsRealAssetsFilterSectorChip(item.id))
    }

    var footer: some View {
        VStack(spacing: footerButtonSpacing) {
            TangemUI.Button(
                label: AttributedString(Localization.commonReset),
                accessibilityLabel: Localization.commonReset,
                action: viewModel.reset
            )
            .size(.x12)
            .styleType(.secondary(.default))
            .horizontalLayout(.infinity)
            .accessibilityIdentifier(MarketsAccessibilityIdentifiers.marketsRealAssetsFilterResetButton)

            TangemUI.Button(
                label: AttributedString(Localization.commonApply),
                accessibilityLabel: Localization.commonApply,
                action: viewModel.apply
            )
            .size(.x12)
            .styleType(.default)
            .horizontalLayout(.infinity)
            .accessibilityIdentifier(MarketsAccessibilityIdentifiers.marketsRealAssetsFilterApplyButton)
        }
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
