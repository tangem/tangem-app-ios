//
//  NewsWidgetViewRedesign.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemUIUtils
import TangemUI
import TangemLocalization

struct NewsWidgetViewRedesign: View {
    @ObservedObject var viewModel: NewsWidgetViewModel

    @ScaledMetric private var scaleFactor: CGFloat = 1

    var body: some View {
        VStack(alignment: .leading, spacing: MarketsWidgetLayout.Item.interItemSpacing) {
            header
                .disableAnimations()

            content
                .id(contentStateID)
                .transition(.opacity)
        }
        .animation(.easeInOut(duration: 0.3), value: contentStateID)
    }

    private var contentStateID: Int {
        switch viewModel.resultState {
        case .loading: return 0
        case .success: return 1
        case .failure: return 2
        }
    }

    // MARK: - Private Properties

    /// News header keeps the same shape as `MarketsCommonWidgetHeaderViewRedesign` but renders
    /// "Tangem AI" as a gradient-colored Text node (per latest Figma) instead of a flat image asset.
    private var header: some View {
        HStack(alignment: .center, spacing: .zero) {
            Text(Localization.commonNews)
                .lineLimit(1)
                .style(.Tangem.Heading20.semibold, color: .Tangem.Text.Neutral.primary)
                .skeletonable(
                    isShown: viewModel.headerLoadingState.isHeaderSkeletonable,
                    size: CGSize(width: 120, height: 24) * scaleFactor,
                    cornerStyle: .capsule
                )

            if viewModel.headerLoadingState.isButtonVisibility {
                FixedSpacer(width: SizeUnit.x2.value)
                tangemAIAccessory
            }

            Spacer(minLength: SizeUnit.x2.value)

            if viewModel.headerLoadingState.isButtonVisibility {
                seeAllButton
            }
        }
        .padding(.vertical, SizeUnit.x2.value)
        .padding(.horizontal, SizeUnit.x2.value)
    }

    private var tangemAIAccessory: some View {
        HStack(spacing: SizeUnit.x1.value) {
            Assets.Glyphs.tripleSparkles.image
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: SizeUnit.x5.value, height: SizeUnit.x5.value)
                .foregroundStyle(NewsHeaderGradient.linearGradient)

            Text("Tangem AI")
                .style(.Tangem.Body16.medium, color: .clear)
                .overlay(
                    NewsHeaderGradient.linearGradient.mask(
                        Text("Tangem AI")
                            .style(.Tangem.Body16.medium, color: .black)
                    )
                )
        }
    }

    private var seeAllButton: some View {
        Button(action: viewModel.handleAllNewsTap) {
            HStack(spacing: .zero) {
                Text(Localization.commonSeeAll)
                    .style(.Tangem.Body16.medium, color: .Tangem.Text.Neutral.primary)

                Assets.chevron.image
                    .renderingMode(.template)
                    .foregroundStyle(Color.Tangem.Graphic.Neutral.tertiaryConstant)
                    .frame(width: SizeUnit.x6.value, height: SizeUnit.x6.value)
            }
        }
        .accessibilityIdentifier(MarketsAccessibilityIdentifiers.marketsSeeAllButton)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.resultState {
        case .success(let state):
            makeSuccessContent(for: state)
        case .failure:
            makeErrorContent()
        case .loading:
            makeLoadingContent()
        }
    }

    func makeSuccessContent(for state: NewsWidgetViewModel.ResultState) -> some View {
        VStack(spacing: Layout.spacingBetweenSections) {
            if let trendingCardNewsItem = state.trendingCardNewsItem {
                TrendingCardNewsViewRedesign(itemState: .success(trendingCardNewsItem))
            }

            // Negative padding bleeds the carousel past the 16pt horizontal padding
            // that MarketsMainView applies to the entire widget container.
            CarouselNewsView(
                itemsState: .success(state.carouselNewsItems),
                onAllNewsTap: viewModel.handleCarouselAllNewsTap,
                onItemAppear: { index in
                    viewModel.handleCarouselItemAppear(at: index)
                }
            )
            .padding(.horizontal, -SizeUnit.x4.value)
        }
    }

    func makeErrorContent() -> some View {
        TangemUnableToLoadDataView(
            isButtonBusy: false,
            retryButtonAction: viewModel.tryLoadAgain
        )
        .padding(.vertical, 58)
        .infinityFrame(axis: .horizontal, alignment: .center)
    }

    func makeLoadingContent() -> some View {
        VStack(spacing: Layout.spacingBetweenSections) {
            TrendingCardNewsSkeletonView()

            MarketsCarouselNewsSkeletonView()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension NewsWidgetViewRedesign {
    enum Layout {
        static let spacingBetweenSections: CGFloat = .unit(.x3)
    }
}

/// Single source of truth for the "Tangem AI" brand gradient (#7b78ff → #c56bcd with the stop at 43.125% per Figma).
/// Used by the news widget header here and by `NewsQuickRecapView`'s title — reference from both sites instead of duplicating.
enum NewsHeaderGradient {
    static let stops: [Gradient.Stop] = [
        .init(color: Color(red: 0x7b / 255, green: 0x78 / 255, blue: 0xff / 255), location: 0),
        .init(color: Color(red: 0xc5 / 255, green: 0x6b / 255, blue: 0xcd / 255), location: 0.43125),
    ]

    static let linearGradient = LinearGradient(stops: stops, startPoint: .leading, endPoint: .trailing)
}
