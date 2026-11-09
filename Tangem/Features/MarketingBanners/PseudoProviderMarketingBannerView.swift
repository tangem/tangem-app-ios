//
//  PseudoProviderMarketingBannerView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils
import TangemLocalization
import TangemAccessibilityIdentifiers

struct PseudoProviderMarketingBannerView: View {
    let viewModel: CallToActionMarketingBannerViewModel<CallToActionMarketingBanner.PseudoProvider>
    let onAction: (CallToActionMarketingBannerAction) -> Void

    private var content: CallToActionMarketingBanner.PseudoProvider {
        viewModel.content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
            topRow

            if content.etaLabel != nil || content.partnerLabel != nil {
                footer
            }
        }
        .padding(Layout.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Color.bgSecondary, in: shape)
        .glowRing(.success, size: .card(cornerRadius: Layout.cornerRadius), isVisible: viewModel.isGlowing)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(MarketingBannerAccessibilityIdentifiers.callToActionBanner(id: viewModel.id))
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous)
    }

    private var topRow: some View {
        HStack(spacing: Layout.topRowSpacing) {
            VStack(alignment: .leading, spacing: Layout.labelSpacing) {
                if let categoryLabel = content.categoryLabel {
                    Text(categoryLabel)
                        .style(DesignSystem.Font.captionMediumToken, color: categoryLabelColor)
                }

                VStack(alignment: .leading, spacing: .zero) {
                    Text(viewModel.title)
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

                    if let subtitle = content.subtitle {
                        Text(subtitle)
                            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

            TangemUI.Button(
                label: viewModel.buttonTitle,
                accessibilityLabel: nil,
                action: { onAction(.open(viewModel.link)) }
            )
            .styleType(.primary)
            .size(.x10)
            .accessibilityIdentifier(MarketingBannerAccessibilityIdentifiers.callToActionBannerButton(id: viewModel.id))

            if viewModel.isDismissible {
                MessageBannerCloseButton(accessibilityLabel: Localization.commonClose) {
                    onAction(.dismiss(campaignId: viewModel.id))
                }
            }
        }
    }

    private var categoryLabelColor: Color {
        viewModel.isGlowing ? DesignSystem.Color.textStatusSuccess : DesignSystem.Color.textAccentViolet
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: Layout.footerSpacing) {
            Separator(height: .minimal, color: DesignSystem.Color.borderSecondary)

            HStack(spacing: Layout.footerItemSpacing) {
                if let etaLabel = content.etaLabel {
                    Text(etaLabel)
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                }

                Spacer(minLength: .zero)

                if let partnerLabel = content.partnerLabel {
                    Text(partnerLabel)
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                }
            }
            .accessibilityElement(children: .combine)
        }
    }
}

// MARK: - Layout

private extension PseudoProviderMarketingBannerView {
    enum Layout {
        static let cornerRadius: CGFloat = 24
        static let padding: CGFloat = 16
        static let sectionSpacing: CGFloat = 16
        static let topRowSpacing: CGFloat = 12
        static let labelSpacing: CGFloat = 8
        static let footerSpacing: CGFloat = 12
        static let footerItemSpacing: CGFloat = 8
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: 8) {
        PseudoProviderMarketingBannerView(
            viewModel: CallToActionMarketingBannerViewModel(
                id: 1,
                title: "Personal support manager",
                buttonTitle: "Request",
                isGlowing: true,
                link: URL(string: "tangem://support")!,
                isDismissible: false,
                content: .init(
                    categoryLabel: "Concierge for large purchases",
                    subtitle: "Pay by bank transfer",
                    etaLabel: "up to 4 hours",
                    partnerLabel: "via MoonPay"
                )
            ),
            onAction: { _ in }
        )

        PseudoProviderMarketingBannerView(
            viewModel: CallToActionMarketingBannerViewModel(
                id: 2,
                title: "Buy with BTC Direct",
                buttonTitle: "Request",
                isGlowing: false,
                link: URL(string: "https://btcdirect.eu")!,
                isDismissible: false,
                content: .init(categoryLabel: "OTC partner service", subtitle: nil, etaLabel: nil, partnerLabel: nil)
            ),
            onAction: { _ in }
        )
    }
    .padding(16)
}
