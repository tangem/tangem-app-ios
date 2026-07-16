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
                    .background(marketsNavigationBarBackground)
                content
            }
        }
        .ignoresSafeArea(.container, edges: .top)
    }
}

private extension ForYouView {
    // MARK: - View properties

    var marketsNavigationBarBackground: some View {
        MarketsNavigationBarBackgroundView(
            backdropViewColor: backgroundColor,
            overlayContentHidingProgress: 1,
            isNavigationBarBackgroundBackdropViewHidden: false,
            isListContentObscured: false
        )
    }

    var backgroundColor: Color {
        DesignSystem.Color.bgPrimary
    }

    var content: some View {
        ScrollView {
            PortfolioReviewView(viewModel: viewModel.portfolioReview)
                .padding(16)
        }
    }

    var navigationBar: some View {
        ZStack {
            Text(Localization.forYouTitle)
                .style(Fonts.Bold.body, color: Colors.Text.primary1)
            HStack {
                NavigationBarButton.back(action: onBackButtonAction).redesigned()
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 64, alignment: .bottom)
    }
}
