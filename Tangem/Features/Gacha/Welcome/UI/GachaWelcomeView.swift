//
//  GachaWelcomeView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct GachaWelcomeView: View {
    @ObservedObject var viewModel: GachaWelcomeViewModel

    let onClose: () -> Void

    @State private var imagePlaceholderSize: CGSize = .zero

    var body: some View {
        ZStack(alignment: .topTrailing) {
            DesignSystem.Color.bgPrimary.ignoresSafeArea()

            scrollableContent
                .ignoresSafeArea(edges: .top)

            NavigationBarButton.close(action: onClose)
                .padding(.top, Metrics.closeTopPadding)
                .padding(.trailing, Metrics.closeTrailingPadding)
        }
        .safeAreaInset(edge: .bottom) {
            Footer(isLoading: viewModel.isOpeningStories, onCreateAccountTap: viewModel.onCreateAccountTap)
        }
        .environment(\.isRedesign, true)
    }
}

private extension GachaWelcomeView {
    // MARK: - View properties

    var scrollableContent: some View {
        ScrollView(showsIndicators: false) {
            ZStack(alignment: .top) {
                imagePlaceholder
                    .readGeometry(\.frame.size, bindTo: $imagePlaceholderSize)

                VStack(spacing: 0) {
                    FixedSpacer(height: max(0, imagePlaceholderSize.height - Metrics.imageContentOverlap))

                    content
                }
            }
        }
    }

    /// Reserves the hero image slot until the final asset lands.
    var imagePlaceholder: some View {
        Color.clear
            .aspectRatio(Metrics.imageAspectRatio, contentMode: .fit)
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
        .padding(.bottom, Metrics.contentBottomPadding)
    }

    var titleBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            // [REDACTED_TODO_COMMENT]
            Text("Open Gacha account")
                .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)

            // [REDACTED_TODO_COMMENT]
            Text("Buy sealed packs of real graded collectible cards — Pokémon, One Piece, sports. Whatever you open is yours: keep it in the insured physical vault, take the instant offer, have the slab shipped to you, or send it to a friend as a gift")
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
        }
    }
}

// MARK: - Metrics

private extension GachaWelcomeView {
    enum Metrics {
        static let closeTopPadding: CGFloat = 8
        static let closeTrailingPadding: CGFloat = 16

        static let imageContentOverlap: CGFloat = 128
        /// The mockup's hero image proportions (405×608).
        static let imageAspectRatio: CGFloat = 405.0 / 608.0

        static let contentHorizontalPadding: CGFloat = 24
        static let contentBottomPadding: CGFloat = 24

        static let benefitsTopPadding: CGFloat = 36
        static let faqTopPadding: CGFloat = 24
    }
}

// MARK: - Previews

#Preview {
    GachaWelcomeView(viewModel: GachaWelcomeViewModel(routable: nil), onClose: {})
}
