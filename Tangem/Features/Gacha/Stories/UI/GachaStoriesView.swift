//
//  GachaStoriesView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct GachaStoriesView: View {
    @ObservedObject var viewModel: GachaStoriesViewModel

    var body: some View {
        ZStack {
            DesignSystem.Color.bgPrimary.ignoresSafeArea()

            tapZones

            slideContent
        }
        .overlay(header, alignment: .top)
        .safeAreaInset(edge: .bottom) { continueButton }
        .environment(\.isRedesign, true)
        .task(viewModel.run)
    }
}

private extension GachaStoriesView {
    // MARK: - View properties

    var header: some View {
        ZStack {
            ProgressBar(
                slidesCount: viewModel.slidesCount,
                currentSlideIndex: viewModel.currentSlideIndex,
                currentSlideProgress: viewModel.currentSlideProgress
            )

            NavigationBarButton.close(action: viewModel.onCloseTap)
                .infinityFrame(axis: .horizontal, alignment: .trailing)
                .padding(.trailing, Metrics.closeTrailingPadding)
        }
        .padding(.top, Metrics.headerTopPadding)
    }

    var tapZones: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                tapZone(onTap: viewModel.onBackwardTap)
                    .frame(width: proxy.size.width * Metrics.backwardTapZoneWidthRatio)

                tapZone(onTap: viewModel.onForwardTap)
            }
        }
    }

    func tapZone(onTap: @escaping () -> Void) -> some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
            .onLongPressGesture(
                minimumDuration: Metrics.pauseLongPressDuration,
                perform: {},
                onPressingChanged: viewModel.onPressingChanged
            )
    }

    var slideContent: some View {
        VStack(spacing: 8) {
            Text(viewModel.currentSlide.title)
                .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)

            Text(viewModel.currentSlide.subtitle)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, Metrics.slideContentHorizontalPadding)
        .padding(.bottom, Metrics.slideContentBottomPadding)
        .infinityFrame(alignment: .bottom)
        .allowsHitTesting(false)
    }

    var continueButton: some View {
        TangemUI.Button(label: viewModel.currentSlide.buttonTitle, accessibilityLabel: nil, action: viewModel.onContinueTap)
            .styleType(.default)
            .horizontalLayout(.infinity)
            .size(.x12)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
    }
}

// MARK: - Slide

extension GachaStoriesView {
    struct Slide {
        let title, subtitle, buttonTitle: String

        // [REDACTED_TODO_COMMENT]
        static let content: [Self] = [
            .init(
                title: "Digital packs.\nPhysical collectibles.",
                subtitle: "Every card is professionally graded, so authenticity is guaranteed — and each one is backed 1:1 by the physical slab in an insured physical vault",
                buttonTitle: "Next"
            ),
            .init(
                title: "High security, tapless design",
                subtitle: "One tap sets up your Solana smart contract, owned by your cold wallet. Collect tapless; every withdrawal still requires your card",
                buttonTitle: "Next"
            ),
            .init(
                title: "There's always a buyer",
                subtitle: "Get 85–93% of your card's insured value. Accept for USDC in Gacha, or tap to withdraw to your cold wallet",
                buttonTitle: "Next"
            ),
            .init(
                title: "Nothing behind the curtain",
                subtitle: "Browse every card before you buy and watch live openings from the blockchain, with each collector's wallet and card value. All in-app",
                buttonTitle: "Next"
            ),
            .init(
                title: "The card is yours, either way",
                subtitle: "Leave it in the physical vault, have it delivered to your address, or send it to a friend as a gift — the slab is redeemable whenever you want it",
                buttonTitle: "Browse packs"
            ),
        ]
    }
}

// MARK: - Metrics

private extension GachaStoriesView {
    enum Metrics {
        static let headerTopPadding: CGFloat = 8
        static let closeTrailingPadding: CGFloat = 16

        static let backwardTapZoneWidthRatio: CGFloat = 1.0 / 3.0
        static let pauseLongPressDuration: TimeInterval = 0.25

        static let slideContentHorizontalPadding: CGFloat = 24
        /// Text-to-button gap per the mockup: 48 here plus the button's own 8pt top inset.
        static let slideContentBottomPadding: CGFloat = 48
    }
}

// MARK: - Previews

#Preview {
    GachaStoriesView(viewModel: GachaStoriesViewModel(routable: nil))
}
