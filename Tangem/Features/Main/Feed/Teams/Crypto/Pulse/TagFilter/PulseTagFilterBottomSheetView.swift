//
//  PulseTagFilterBottomSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemLocalization
import TangemPolymarketUI
import TangemUI
import TangemUIUtils

struct PulseTagFilterBottomSheetView: View {
    @ObservedObject private var viewModel: PulseTagFilterBottomSheetViewModel

    @State private var headerHeight: CGFloat = 0

    @ScaledMetric private var contentHorizontalPadding: CGFloat = 16
    @ScaledMetric private var headerVerticalPadding: CGFloat = 12
    @ScaledMetric private var headerSpacing: CGFloat = 12
    @ScaledMetric private var contentTopSpacing: CGFloat = 12
    @ScaledMetric private var footerPadding: CGFloat = 16
    @ScaledMetric private var footerButtonSpacing: CGFloat = 8
    @ScaledMetric private var sectionTitleVerticalPadding: CGFloat = 8
    @ScaledMetric private var sectionSpacing: CGFloat = 24
    @ScaledMetric private var rowVerticalPadding: CGFloat = 12
    @ScaledMetric private var rowCounterSpacing: CGFloat = 12
    @ScaledMetric private var rowTrailingSpacing: CGFloat = 2
    @ScaledMetric private var radioIconSide: CGFloat = 20
    @ScaledMetric private var chipSpacing: CGFloat = 4
    @ScaledMetric private var chipsTopPadding: CGFloat = 8
    @ScaledMetric private var chipHorizontalPadding: CGFloat = 12
    @ScaledMetric private var chipVerticalPadding: CGFloat = 8
    @ScaledMetric private var statePlaceholderMinHeight: CGFloat = 320
    @ScaledMetric private var skeletonTitleWidth: CGFloat = 64
    @ScaledMetric private var skeletonTitleHeight: CGFloat = 12
    @ScaledMetric private var skeletonChipWidth: CGFloat = 60
    @ScaledMetric private var skeletonChipHeight: CGFloat = 36
    @ScaledMetric private var skeletonRowWidth: CGFloat = 184
    @ScaledMetric private var skeletonRowHeight: CGFloat = 14
    @ScaledMetric private var skeletonRowVerticalPadding: CGFloat = 19

    init(viewModel: PulseTagFilterBottomSheetViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: .zero) {
            ZStack(alignment: .top) {
                scrollContent
                header
            }

            if viewModel.showsFooter {
                footer
                    .padding(footerPadding)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(DesignSystem.Color.bgPrimary)
        .onAppear(perform: viewModel.onViewAppear)
        .animation(.easeInOut(duration: 0.2), value: viewModel.loadingState)
        .animation(.easeInOut(duration: 0.2), value: viewModel.showsFooter)
    }
}

// MARK: - Subviews

private extension PulseTagFilterBottomSheetView {
    var scrollContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            content
                .padding(.horizontal, contentHorizontalPadding)
                .padding(.top, headerHeight + contentTopSpacing)
        }
        .scrollDismissesKeyboard(.interactively)
        .frame(idealHeight: scrollIdealHeight)
    }

    var scrollIdealHeight: CGFloat? {
        guard viewModel.loadingState == .loaded, viewModel.categoryItems.count > Constants.maxRowsToMeasure else {
            return nil
        }

        return Constants.loadedIdealHeight
    }

    @ViewBuilder
    var content: some View {
        switch viewModel.loadingState {
        case .loading:
            skeleton
        case .failed:
            PolymarketEmptyMessageView(message: Localization.marketFailedToLoadFilters, onRetry: viewModel.retry)
                .frame(minHeight: statePlaceholderMinHeight)
        case .loaded:
            loadedContent
        }
    }

    var loadedContent: some View {
        LazyVStack(alignment: .leading, spacing: .zero) {
            if !viewModel.featuredItems.isEmpty {
                sectionTitle(Localization.commonFeatured)

                featuredChips
                    .padding(.top, chipsTopPadding)
                    .padding(.bottom, sectionSpacing)
            }

            if viewModel.showsNoResults {
                Text(Localization.marketsSearchTokenNoResultTitle)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textTertiary)
                    .frame(maxWidth: .infinity, minHeight: statePlaceholderMinHeight)
            } else {
                sectionTitle(Localization.marketCategories)

                ForEach(viewModel.categoryItems) { item in
                    categoryRow(item)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var header: some View {
        HStack(spacing: headerSpacing) {
            Search(text: $viewModel.searchText)
                .placeholder(Localization.commonSearch)
                .showsCloseButton(false)
                .textFieldAccessibilityIdentifier(MarketsAccessibilityIdentifiers.marketsPulseTagFilterSearchField)

            closeButton
        }
        .padding(.horizontal, contentHorizontalPadding)
        .padding(.vertical, headerVerticalPadding)
        .background(DesignSystem.Color.bgPrimary)
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
        .accessibilityIdentifier(MarketsAccessibilityIdentifiers.marketsPulseTagFilterCloseButton)
    }

    func sectionTitle(_ title: String) -> some View {
        Text(title)
            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            .padding(.vertical, sectionTitleVerticalPadding)
    }

    var featuredChips: some View {
        HorizontalFlowLayout(
            items: viewModel.featuredItems,
            alignment: .leading,
            horizontalSpacing: chipSpacing,
            verticalSpacing: chipSpacing
        ) { item in
            featuredChip(item)
        }
    }

    func featuredChip(_ item: PulseTagFilterBottomSheetViewModel.Item) -> some View {
        let isSelected = viewModel.isSelected(item)

        return SwiftUI.Button(action: { viewModel.select(item) }) {
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
        .accessibilityIdentifier(MarketsAccessibilityIdentifiers.marketsPulseTagFilterFeaturedChip(item.id))
    }

    func categoryRow(_ item: PulseTagFilterBottomSheetViewModel.Item) -> some View {
        let isSelected = viewModel.isSelected(item)

        return SwiftUI.Button(action: { viewModel.select(item) }) {
            HStack(spacing: rowCounterSpacing) {
                Text(item.title)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                    .lineLimit(1)

                Spacer(minLength: .zero)

                VStack(alignment: .trailing, spacing: rowTrailingSpacing) {
                    Text(item.marketCap)
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

                    Text(Localization.commonAssetsCount(item.tokensCount))
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                }
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)

                radioIcon(isSelected: isSelected)
            }
            .padding(.vertical, rowVerticalPadding)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(MarketsAccessibilityIdentifiers.marketsPulseTagFilterCategoryOption(item.id))
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
        .frame(size: .init(bothDimensions: radioIconSide))
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    var skeleton: some View {
        VStack(alignment: .leading, spacing: .zero) {
            skeletonBlock(width: skeletonTitleWidth, height: skeletonTitleHeight)
                .padding(.vertical, sectionTitleVerticalPadding)

            HStack(spacing: chipSpacing) {
                ForEach(0 ..< Constants.skeletonChipCount, id: \.self) { _ in
                    skeletonBlock(width: skeletonChipWidth, height: skeletonChipHeight)
                }
            }
            .padding(.top, chipsTopPadding)
            .padding(.bottom, sectionSpacing)

            skeletonBlock(width: skeletonTitleWidth, height: skeletonTitleHeight)
                .padding(.vertical, sectionTitleVerticalPadding)

            ForEach(0 ..< Constants.skeletonRowCount, id: \.self) { _ in
                skeletonBlock(width: skeletonRowWidth, height: skeletonRowHeight)
                    .padding(.vertical, skeletonRowVerticalPadding)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .allowsHitTesting(false)
    }

    func skeletonBlock(width: CGFloat, height: CGFloat) -> some View {
        SkeletonView()
            .frame(width: width, height: height)
            .clipShape(.capsule)
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
            .accessibilityIdentifier(MarketsAccessibilityIdentifiers.marketsPulseTagFilterResetButton)

            TangemUI.Button(
                label: AttributedString(Localization.commonApply),
                accessibilityLabel: Localization.commonApply,
                action: viewModel.apply
            )
            .size(.x12)
            .styleType(.default)
            .horizontalLayout(.infinity)
            .accessibilityIdentifier(MarketsAccessibilityIdentifiers.marketsPulseTagFilterApplyButton)
        }
    }
}

// MARK: - Constants

private extension PulseTagFilterBottomSheetView {
    enum Constants {
        static let skeletonChipCount = 5
        static let skeletonRowCount = 10
        static let loadedIdealHeight: CGFloat = 10_000
        static let maxRowsToMeasure = 50
    }
}

// MARK: - Previews

private struct PreviewGeckoCategoriesProvider: MarketsGeckoCategoriesProvider {
    let result: Result<MarketsGeckoCategoriesSnapshot, Error>

    func categories() async throws -> MarketsGeckoCategoriesSnapshot {
        try await Task.sleep(for: .seconds(1))
        return try result.get()
    }
}

private let previewCategories: [MarketsDTO.GeckoCategories.Category] = [
    .init(id: "smart-contract-platform", name: "Smart Contract Platform", marketCap: 2_198_425_453_845, marketCapChange24h: 0.58, featured: true, tokensCount: 548),
    .init(id: "layer-1", name: "Layer 1 (L1)", marketCap: 2_176_316_209_817, marketCapChange24h: 0.67, featured: true, tokensCount: 296),
    .init(id: "bitcoin-ecosystem", name: "Bitcoin Ecosystem", marketCap: 1_620_000_000_000, marketCapChange24h: 0.1, featured: false, tokensCount: 212),
    .init(id: "proof-of-work-pow", name: "Proof of Work (PoW)", marketCap: 1_590_000_000_000, marketCapChange24h: -0.3, featured: true, tokensCount: 180),
    .init(id: "ethereum-ecosystem", name: "Ethereum Ecosystem", marketCap: 620_000_000_000, marketCapChange24h: 1.2, featured: false, tokensCount: 1200),
    .init(id: "meme-token", name: "Meme", marketCap: 52_000_000_000, marketCapChange24h: -4.5, featured: true, tokensCount: 900),
    .init(id: "decentralized-identifier-did", name: "DID", marketCap: 1_800_000_000, marketCapChange24h: 2.1, featured: true, tokensCount: 24),
]

#Preview("Loaded") {
    PulseTagFilterBottomSheetView(
        viewModel: PulseTagFilterBottomSheetViewModel(
            input: PulseTagFilterInput(selectedTagID: "decentralized-identifier-did", onApply: { _ in }),
            categoriesProvider: PreviewGeckoCategoriesProvider(
                result: .success(MarketsGeckoCategoriesSnapshot(categories: previewCategories, country: "US"))
            ),
            onDismiss: {}
        )
    )
    .preferredColorScheme(.dark)
}

#Preview("Failed") {
    PulseTagFilterBottomSheetView(
        viewModel: PulseTagFilterBottomSheetViewModel(
            input: PulseTagFilterInput(selectedTagID: nil, onApply: { _ in }),
            categoriesProvider: PreviewGeckoCategoriesProvider(result: .failure(CancellationError())),
            onDismiss: {}
        )
    )
    .preferredColorScheme(.dark)
}
