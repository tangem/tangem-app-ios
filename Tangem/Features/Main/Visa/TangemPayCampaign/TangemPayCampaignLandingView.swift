//
//  TangemPayCampaignLandingView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct TangemPayCampaignLandingView: View {
    @ObservedObject var viewModel: TangemPayCampaignViewModel

    let landing: TangemPayCampaignLanding

    var body: some View {
        TangemPayCampaignLayout(
            onClose: viewModel.showsCloseButton ? viewModel.close : nil,
            card: {
                TangemPayCampaignCardArtView(url: landing.cardArtURL)
            },
            texts: {
                Text(Localization.tangempayCampaignLandingTitle)
                    .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)

                bullets
                    .padding(.top, Constants.titleToBulletsGap)
            },
            footer: {
                footer
            }
        )
    }

    private var bullets: some View {
        VStack(alignment: .leading, spacing: Constants.bulletSpacing) {
            bullet(
                title: Localization.tangempayOnboardingSecurityTitle,
                description: Localization.tangempayOnboardingSecurityDescription
            )
            bullet(
                title: Localization.tangempayCampaignCashbackTitle,
                description: Localization.tangempayCampaignCashbackDescription
            )
            bullet(
                title: Localization.tangempayOnboardingPayTitle,
                description: Localization.tangempayCampaignSpendDescription
            )
        }
    }

    private func bullet(title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: Constants.bulletIconGap) {
            DesignSystem.Icons.Info.regular20.image
                .renderingMode(.template)
                .foregroundStyle(DesignSystem.Color.iconPrimary)

            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)

                Text(description)
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
            }
            .infinityFrame(axis: .horizontal, alignment: .leading)
        }
    }

    private var footer: some View {
        VStack(spacing: Constants.footerSpacing) {
            if viewModel.showsLegalCaption {
                legalCaption
            }

            TangemUI.Button(
                label: Localization.tangempayOnboardingGetCardButtonText,
                accessibilityLabel: nil,
                action: viewModel.getCard
            )
            .iconEnd(viewModel.showsCTAIcon ? DesignSystem.Icons.LogoTangem.regular24 : nil)
            .styleType(.default)
            .horizontalLayout(.infinity)
            .loading(.spinner(if: viewModel.isCTALoading))
            .size(.x12)
        }
        .padding(.horizontal, Constants.footerHorizontalPadding)
        .padding(.vertical, Constants.footerVerticalPadding)
        .background(alignment: .bottom) {
            BottomFadeWithBlur(backgroundColor: DesignSystem.Color.bgPrimary)
        }
    }

    private var legalCaption: some View {
        Text(legalCaptionText)
            .multilineTextAlignment(.center)
            .environment(\.openURL, OpenURLAction { url in
                viewModel.openLegalDocument(url: url)
                return .handled
            })
    }

    private var legalCaptionText: AttributedString {
        let terms = Localization.introductionTermsOfService
        let privacy = Localization.commonPrivacyPolicy

        var string = AttributedString(Localization.introductionLegal(terms, privacy))
        string.setFontStyle(DesignSystem.Font.captionMediumToken)
        string.foregroundColor = DesignSystem.Color.textSecondary

        if let range = string.range(of: terms) {
            string[range].foregroundColor = DesignSystem.Color.textPrimary
            string[range].link = AppConstants.tosURL
        }

        if let range = string.range(of: privacy) {
            string[range].foregroundColor = DesignSystem.Color.textPrimary
            string[range].link = AppConstants.tangemPayPrivacyPolicyURL
        }

        return string
    }
}

private extension TangemPayCampaignLandingView {
    enum Constants {
        static let titleToBulletsGap: CGFloat = 24
        static let bulletSpacing: CGFloat = 16
        static let bulletIconGap: CGFloat = 8
        static let footerSpacing: CGFloat = 12
        static let footerHorizontalPadding: CGFloat = 16
        static let footerVerticalPadding: CGFloat = 8
    }
}
