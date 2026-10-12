//
//  TangemPayCampaignLayout.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

/// Shared frame for the campaign landings and their skeleton — the card holds the top, the text block
/// the bottom, and spare height falls between them.
struct TangemPayCampaignLayout<Card: View, Texts: View, Footer: View>: View {
    private let onClose: (() -> Void)?
    private let card: Card
    private let texts: Texts
    private let footer: Footer

    init(
        onClose: (() -> Void)?,
        @ViewBuilder card: () -> Card,
        @ViewBuilder texts: () -> Texts,
        @ViewBuilder footer: () -> Footer
    ) {
        self.onClose = onClose
        self.card = card()
        self.texts = texts()
        self.footer = footer()
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    card
                        .padding(.top, Constants.cardTopPadding)

                    Spacer(minLength: Constants.cardToTextsGap)

                    VStack(alignment: .leading, spacing: 0) {
                        texts
                    }
                    .padding(.bottom, Constants.textsBottomPadding)
                }
                .frame(minHeight: proxy.size.height, alignment: .top)
                .padding(.horizontal, Constants.horizontalPadding)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
        }
        .background { DesignSystem.Color.bgPrimary.ignoresSafeArea() }
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
        .topNavigation(leading: .none, onClose: onClose) {
            // Without a close button the bar has no content and collapses, taking the card with it.
            Color.clear.frame(width: 0, height: .unit(.x11))
        }
    }
}

private enum Constants {
    static let horizontalPadding: CGFloat = 24
    static let cardTopPadding: CGFloat = 8
    static let cardToTextsGap: CGFloat = 24
    /// Design puts 38pt between the texts and the footer's caption; the footer adds the last 8 itself.
    static let textsBottomPadding: CGFloat = 30
}
