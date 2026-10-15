//
//  TangemPayCampaignIssueCardView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct TangemPayCampaignIssueCardView: View {
    @ObservedObject var viewModel: TangemPayCampaignViewModel

    let issueCard: TangemPayCampaignIssueCard

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            TangemPayCampaignCardArtView(
                url: issueCard.cardArtURL,
                cornerRadius: TangemPayCampaignCardArtView.Constants.issueCardCornerRadius,
                showsDigitalCardIndicator: true
            )

            Spacer()

            virtualBadge
                .infinityFrame(axis: .horizontal, alignment: .leading)
                .padding(.horizontal, Constants.badgeHorizontalPadding)
                .padding(.bottom, Constants.badgeToRowsGap)

            TangemPayOrderCardInfoRowsView(rows: viewModel.issueCardInfoRows)
                .padding(.horizontal, Constants.rowsHorizontalPadding)
                .padding(.bottom, Constants.rowsToFooterGap)
        }
        .background { background }
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
        .topNavigation(
            title: Localization.tangempayCampaignIssueCardTitle,
            leading: .none,
            onClose: viewModel.close
        )
    }

    private var background: some View {
        DesignSystem.Color.bgPrimary
            .overlay(alignment: .top) {
                (issueCard.isBasicTariff ? Assets.Visa.orderCardBgBasic : Assets.Visa.orderCardBgPlus)
                    .image
                    .resizable()
                    .scaledToFit()
            }
            .ignoresSafeArea()
    }

    private var virtualBadge: some View {
        Text(Localization.tangempayOrderTypeSegmentVirtual)
            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
            .padding(.horizontal, Constants.badgeInnerHorizontalPadding)
            .padding(.vertical, Constants.badgeInnerVerticalPadding)
            .tangemMaterialSurface(in: .capsule)
    }

    private var footer: some View {
        TangemUI.Button(
            label: Localization.tangempayCampaignIssueButton,
            accessibilityLabel: nil,
            action: viewModel.issueCampaignCard
        )
        .styleType(.primary)
        .horizontalLayout(.infinity)
        .loading(.spinner(if: viewModel.isCTALoading))
        .size(.x12)
        .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.campaignIssueCardButton)
        .padding(.horizontal, Constants.footerHorizontalPadding)
        .padding(.vertical, Constants.footerVerticalPadding)
        .background(alignment: .bottom) {
            BottomFadeWithBlur(backgroundColor: DesignSystem.Color.bgPrimary)
        }
    }
}

private extension TangemPayCampaignIssueCardView {
    enum Constants {
        static let badgeHorizontalPadding: CGFloat = 16
        static let badgeInnerHorizontalPadding: CGFloat = 16
        static let badgeInnerVerticalPadding: CGFloat = 12
        static let badgeToRowsGap: CGFloat = 16

        static let rowsHorizontalPadding: CGFloat = 8
        /// With the footer's own top padding this makes the 64pt the design asks for.
        static let rowsToFooterGap: CGFloat = 52
        static let footerHorizontalPadding: CGFloat = 16
        static let footerVerticalPadding: CGFloat = 12
    }
}
