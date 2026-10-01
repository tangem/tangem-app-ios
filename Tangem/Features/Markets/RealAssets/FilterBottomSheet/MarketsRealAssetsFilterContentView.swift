//
//  MarketsRealAssetsFilterContentView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct MarketsRealAssetsFilterContentView: View {
    @ObservedObject var viewModel: MarketsRealAssetsFilterBottomSheetViewModel

    @ScaledMetric private var sectionTitleVerticalPadding: CGFloat = 8
    @ScaledMetric private var sectionSpacing: CGFloat = 24
    @ScaledMetric private var rowVerticalPadding: CGFloat = 18
    @ScaledMetric private var rowCounterSpacing: CGFloat = 12
    @ScaledMetric private var chipSpacing: CGFloat = 4
    @ScaledMetric private var chipsTopPadding: CGFloat = 8
    @ScaledMetric private var chipHorizontalPadding: CGFloat = 12
    @ScaledMetric private var chipVerticalPadding: CGFloat = 8

    var body: some View {
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
}

private extension MarketsRealAssetsFilterContentView {
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

                TangemUI.Checkmark(checked: isSelected, action: {})
                    .expandsHitArea(false)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, rowVerticalPadding)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(MarketsAccessibilityIdentifiers.marketsRealAssetsFilterCategoryOption(category.code))
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
}
