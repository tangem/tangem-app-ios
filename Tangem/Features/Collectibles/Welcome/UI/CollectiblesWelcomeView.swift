//
//  CollectiblesWelcomeView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct CollectiblesWelcomeView: View {
    @ObservedObject var viewModel: CollectiblesWelcomeViewModel

    let dismissStyle: CollectiblesDismissStyle
    let onDismiss: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            DesignSystem.Color.bgPrimary.ignoresSafeArea()

            scrollableContent
                .ignoresSafeArea(edges: .top)

            dismissStyle.button(action: onDismiss)
                .padding(.top, Metrics.backTopPadding)
                .padding(.leading, Metrics.backLeadingPadding)
        }
        .safeAreaInset(edge: .bottom) {
            Footer(
                signingActionButtonType: viewModel.signingActionButtonType,
                actionTitle: viewModel.actionTitle,
                isLoading: viewModel.isOnboarding,
                onActionTap: viewModel.onActionTap,
                onTermsTap: viewModel.onLegalTermsTap(url:)
            )
        }
        .toolbar(.hidden, for: .navigationBar)
        .alert(item: $viewModel.alert, content: \.alert)
    }
}

private extension CollectiblesWelcomeView {
    // MARK: - View properties

    var scrollableContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                hero

                content
            }
        }
        .coordinateSpace(name: Constants.scrollSpace)
    }

    var hero: some View {
        OnboardingHero(image: Assets.Collectibles.welcomeBackground, tint: .standard, scrollSpace: Constants.scrollSpace)
    }

    var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            titleBlock

            BenefitCollection()
                .padding(.top, Metrics.benefitsTopPadding)

            FAQCollection()
                .padding(.top, Metrics.faqTopPadding)
        }
        .padding(.horizontal, Metrics.contentHorizontalPadding)
        .padding(.top, Metrics.contentTopPadding)
        .padding(.bottom, Metrics.contentBottomPadding)
    }

    var titleBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.title)
                .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)

            Text(Localization.collectiblesWelcomeDescription)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
        }
    }
}

// MARK: - Constants

private extension CollectiblesWelcomeView {
    enum Constants {
        static let scrollSpace = "collectibles_welcome_scroll"
    }
}

// MARK: - Metrics

private extension CollectiblesWelcomeView {
    enum Metrics {
        static let backTopPadding: CGFloat = 8
        static let backLeadingPadding: CGFloat = 16

        static let contentHorizontalPadding: CGFloat = 24
        static let contentTopPadding: CGFloat = 12
        static let contentBottomPadding: CGFloat = 18

        static let benefitsTopPadding: CGFloat = 36
        static let faqTopPadding: CGFloat = 24
    }
}

// MARK: - Previews

#Preview {
    CollectiblesWelcomeView(viewModel: CollectiblesWelcomeViewModel(routable: nil, signingActionButtonType: .requiredNFCInteraction), dismissStyle: .back, onDismiss: {})
}
