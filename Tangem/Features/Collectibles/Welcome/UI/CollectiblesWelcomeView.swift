//
//  CollectiblesWelcomeView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct CollectiblesWelcomeView: View {
    @ObservedObject var viewModel: CollectiblesWelcomeViewModel

    let onBack: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            DesignSystem.Color.bgPrimary.ignoresSafeArea()

            scrollableContent
                .ignoresSafeArea(edges: .top)

            NavigationBarButton.back(action: onBack)
                .padding(.top, Metrics.backTopPadding)
                .padding(.leading, Metrics.backLeadingPadding)
        }
        .safeAreaInset(edge: .bottom) {
            Footer(
                isLoading: viewModel.isOnboarding,
                onCreateAccountTap: viewModel.onCreateAccountTap,
                onTermsTap: viewModel.onLegalTermsTap(url:)
            )
        }
        .environment(\.isRedesign, true)
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
        GeometryReader { proxy in
            let overscroll = max(0, proxy.frame(in: .named(Constants.scrollSpace)).minY)
            let height = proxy.size.width / Metrics.imageAspectRatio

            Assets.Collectibles.welcomeBackground.image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: proxy.size.width, height: height + overscroll)
                .clipped()
                .overlay { heroTint }
                .offset(y: -overscroll)
        }
        .aspectRatio(Metrics.heroSlotAspectRatio, contentMode: .fit)
    }

    var heroTint: some View {
        LinearGradient(
            stops: [
                .init(color: DesignSystem.Color.bgPrimary.opacity(0), location: Metrics.heroTintStart),
                .init(color: DesignSystem.Color.bgPrimary, location: Metrics.heroTintEnd),
                .init(color: DesignSystem.Color.bgPrimary, location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
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
            // [REDACTED_TODO_COMMENT]
            Text("Create your Tangem Packs account")
                .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)

            // [REDACTED_TODO_COMMENT]
            Text("Buy packs containing physical authentic graded collectible cards – Pokémon, One Piece and Sports. Each pack opening reveals a card allocated to you. Keep eligible cards in insured vaults, request delivery, send a card as a gift, or explore available sale options")
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

        /// The mockup's hero image (402×608); its bitmap is placed 405 wide and cropped to the frame.
        static let imageAspectRatio: CGFloat = 402.0 / 608.0
        /// The mockup starts the content at 495 of the image's 608: the slot ends there and the image overflows it.
        static let heroSlotAspectRatio: CGFloat = 402.0 / 495.0
        /// The mockup's tint runs from 380 of the image's 608 and is opaque by its bottom edge.
        static let heroTintStart: CGFloat = 380.0 / 608.0
        static let heroTintEnd: CGFloat = 600.0 / 608.0

        static let contentHorizontalPadding: CGFloat = 24
        static let contentTopPadding: CGFloat = 12
        static let contentBottomPadding: CGFloat = 24

        static let benefitsTopPadding: CGFloat = 36
        static let faqTopPadding: CGFloat = 24
    }
}

// MARK: - Previews

#Preview {
    CollectiblesWelcomeView(viewModel: CollectiblesWelcomeViewModel(routable: nil), onBack: {})
}
