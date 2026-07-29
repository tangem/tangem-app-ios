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
            VStack(spacing: 48) {
                PortfolioReviewOutdatedDataBannerView(viewModel: viewModel.portfolioReviewViewModel)
                portfolioReviewSection
                EarnOpportunitiesView(viewModel: viewModel.earnOpportunitiesViewModel)
            }
            .padding(16)
        }
    }

    private var portfolioReviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Text(Localization.forYouPortfolioReviewTitle)
                    .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)

                Spacer(minLength: 8)

                ForYouAccountSelectorChipView(viewModel: viewModel.accountSelectorChipViewModel)
            }

            PortfolioReviewView(viewModel: viewModel.portfolioReviewViewModel)
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

#Preview {
    NavigationStack {
        ForYouView(viewModel: ForYouViewModel(selectedAccountsProvider: ForYouSelectedAccountsProvider()), onBackButtonAction: {})
    }
}
