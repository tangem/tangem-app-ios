//
//  ForYouView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils
import TangemLocalization

struct ForYouView: View {
    @ObservedObject var viewModel: ForYouViewModel

    let onBackButtonAction: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                navigationBar
                    .background {
                        MarketsNavigationBarBackgroundView(
                            backdropViewColor: backgroundColor,
                            overlayContentHidingProgress: 1,
                            isNavigationBarBackgroundBackdropViewHidden: false,
                            isListContentObscured: false
                        )
                    }

                content
            }
        }
        .ignoresSafeArea(.container, edges: .top)
    }

    private var backgroundColor: Color {
        DesignSystem.Color.bgPrimary
    }

    // MARK: - Content

    private var content: some View {
        ScrollView {
            VStack(spacing: 8) {
                notifications

                periodPicker

                PortfolioTokenListView(viewModel: viewModel.tokenListViewModel)
            }
            .padding(16)
        }
    }

    @ViewBuilder
    private var notifications: some View {
        ForEach(viewModel.notifications) { input in
            NotificationView(input: input)
        }
    }

    @ViewBuilder
    private var periodPicker: some View {
        switch viewModel.portfolioReview {
        case .content(let content):
            ForYouPeriodPickerView(segments: content.periodSegments, selection: $viewModel.selectedPeriod)

        case .loading:
            TangemShimmer()
                .variant(.custom(height: 40, cornerRadius: 20))
                .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Navigation bar

    private var navigationBar: some View {
        ZStack {
            Text(Localization.forYouTitle)
                .style(Fonts.Bold.body, color: Colors.Text.primary1)

            HStack {
                // Liquid Glass back button on iOS 26 (system-label / circle fallbacks otherwise).
                NavigationBarButton.back(action: onBackButtonAction)
                    .redesigned()

                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 64, alignment: .bottom)
    }
}

// MARK: - Previews

#Preview("Content") {
    func item(id: String, symbol: String, subtitle: String, fiat: String, percent: String) -> ForYouTokenListItem {
        ForYouTokenListItem(
            id: id,
            assetRow: ForYouTokenRowData(
                id: id,
                isLoading: false,
                symbol: symbol,
                tokenIconInfo: nil,
                sentiment: .positive,
                subtitle: .text(subtitle),
                end: .values(fiat: fiat, percent: percent)
            ),
            networkRows: [],
            isExpanded: false,
            isExpandable: true
        )
    }

    let content = PortfolioReviewState.content(
        PortfolioReviewState.Content(
            tokenList: [
                item(id: "btc", symbol: "Bitcoin", subtitle: "Main network", fiat: "$849", percent: "8.49%"),
                item(id: "sol", symbol: "Solana", subtitle: "2 networks", fiat: "$700", percent: "7.0%"),
            ],
            periodSegments: ForYouPeriodSegment.all
        )
    )

    return NavigationStack {
        ForYouView(viewModel: ForYouViewModel(previewState: content), onBackButtonAction: {})
    }
}

#Preview("Loading") {
    NavigationStack {
        ForYouView(viewModel: ForYouViewModel(previewState: PortfolioReviewState.loadingPlaceholder), onBackButtonAction: {})
    }
}
