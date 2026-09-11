//
//  TangemPayOrderCardSuccessView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct TangemPayOrderCardSuccessView: View {
    @ObservedObject var viewModel: TangemPayOrderCardSuccessViewModel

    var body: some View {
        VStack(spacing: 0) {
            content
                .padding(.top, Constants.contentTopMargin)

            Spacer(minLength: Constants.contentToFooterMinSpacing)

            footer
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { background }
        .topNavigation(leading: .none)
    }

    private var content: some View {
        VStack(spacing: 0) {
            DesignSystem.Icons.Checkmark.regular24.image
                .renderingMode(.template)
                .resizable()
                .frame(width: Constants.checkmarkSize, height: Constants.checkmarkSize)
                .foregroundStyle(DesignSystem.Color.iconStatusSuccess)

            Text(viewModel.title)
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
                .padding(.top, Constants.checkmarkToTitleSpacing)

            Text(viewModel.deliveryNote)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                .padding(.top, Constants.titleToNoteSpacing)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, Constants.contentHorizontalPadding)
    }

    private var footer: some View {
        VStack(spacing: Constants.footerSpacing) {
            if let emailNote = viewModel.emailNote {
                Text(emailNote)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Constants.contentHorizontalPadding)
            }

            TangemUI.Button(
                label: AttributedString(Localization.tangempayOrderSuccessShowCard),
                accessibilityLabel: Localization.tangempayOrderSuccessShowCard,
                action: viewModel.showCard
            )
            .size(.x12)
            .styleType(.default)
            .horizontalLayout(.infinity)
            .padding(.horizontal, Constants.footerHorizontalPadding)
        }
        .padding(.vertical, Constants.footerVerticalPadding)
    }

    private var background: some View {
        ZStack(alignment: .topLeading) {
            Circle()
                .fill(Color(hex: Constants.outerGlowHex).opacity(Constants.outerGlowOpacity))
                .frame(width: Constants.outerGlowSize, height: Constants.outerGlowSize)
                .offset(x: Constants.outerGlowOrigin.x, y: Constants.outerGlowOrigin.y)
                .blur(radius: Constants.outerGlowBlur)

            Circle()
                .fill(Color(hex: Constants.innerGlowHex).opacity(Constants.innerGlowOpacity))
                .frame(width: Constants.innerGlowSize, height: Constants.innerGlowSize)
                .offset(x: Constants.innerGlowOrigin.x, y: Constants.innerGlowOrigin.y)
                .blur(radius: Constants.innerGlowBlur)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DesignSystem.Color.bgPrimary)
        .glowRing(.success, cornerRadius: Constants.glowRingCornerRadius)
        .ignoresSafeArea()
    }
}

private extension TangemPayOrderCardSuccessView {
    enum Constants {
        static let checkmarkSize: CGFloat = 40
        static let contentTopMargin: CGFloat = 244
        static let contentToFooterMinSpacing: CGFloat = 24
        static let contentHorizontalPadding: CGFloat = 24
        static let checkmarkToTitleSpacing: CGFloat = 20
        static let titleToNoteSpacing: CGFloat = 8

        static let footerSpacing: CGFloat = 12
        static let footerVerticalPadding: CGFloat = 12
        static let footerHorizontalPadding: CGFloat = 16

        static let outerGlowHex = "1E6110"
        static let outerGlowSize: CGFloat = 415
        static let outerGlowOrigin = CGPoint(x: -85, y: -101)
        static let outerGlowOpacity: Double = 0.1
        static let outerGlowBlur: CGFloat = 128

        static let innerGlowHex = "2DAE3B"
        static let innerGlowSize: CGFloat = 346
        static let innerGlowOrigin = CGPoint(x: 255, y: -151)
        static let innerGlowOpacity: Double = 0.4
        static let innerGlowBlur: CGFloat = 96

        /// Matches the Figma `screen-radius` token — the ring hugs the device bezel.
        static let glowRingCornerRadius: CGFloat = 55
    }
}
