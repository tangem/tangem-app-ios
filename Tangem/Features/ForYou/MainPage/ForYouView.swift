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
        content
            .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
            .safeAreaInset(edge: .top, spacing: 0) { navigationBar }
    }
}

private extension ForYouView {
    // MARK: - View properties

    var content: some View {
        ScrollView {
            VStack(spacing: 48) {
                PortfolioReviewOutdatedDataBannerView(viewModel: viewModel.portfolioReviewViewModel)
                portfolioReviewSection
                EarnOpportunitiesView(viewModel: viewModel.earnOpportunitiesViewModel)
            }
            .padding(16)
        }
    }

    var portfolioReviewSection: some View {
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

    var navigationBar: some View {
        NavigationHeader(
            leadingContent: NavigationBarButton.back(action: onBackButtonAction).redesigned,
            principalContent: {
                Text(Localization.forYouTitle)
                    .style(Fonts.Bold.body, color: Colors.Text.primary1)
            },
            trailingContent: EmptyView.init
        )
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        ForYouView(viewModel: ForYouViewModel(selectedAccountsProvider: ForYouSelectedAccountsProvider()), onBackButtonAction: {})
    }
}
