//
//  StandaloneCallToActionMarketingBannerView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemLocalization
import TangemAccessibilityIdentifiers

struct StandaloneCallToActionMarketingBannerView: View {
    let viewModel: CallToActionMarketingBannerViewModel<CallToActionMarketingBanner.Standalone>
    let onAction: (CallToActionMarketingBannerAction) -> Void

    private var content: CallToActionMarketingBanner.Standalone {
        viewModel.content
    }

    var body: some View {
        MessageBanner(title: viewModel.title, description: content.subtitle)
            .slotStart { leadingIcon }
            .slotEnd { trailingContent }
            .primaryButton(MessageBannerButton(
                title: viewModel.buttonTitle,
                accessibilityIdentifier: MarketingBannerAccessibilityIdentifiers.callToActionBannerButton(id: viewModel.id),
                action: { onAction(.open(viewModel.link)) }
            ))
            .glowRing(glowRing)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(MarketingBannerAccessibilityIdentifiers.callToActionBanner(id: viewModel.id))
    }

    private var glowRing: GlowRingAppearance? {
        viewModel.isGlowing ? .magic : nil
    }

    @ViewBuilder
    private var leadingIcon: some View {
        if viewModel.isDismissible {
            iconView
        }
    }

    @ViewBuilder
    private var trailingContent: some View {
        if viewModel.isDismissible {
            MessageBannerCloseButton(accessibilityLabel: Localization.commonClose) {
                onAction(.dismiss(campaignId: viewModel.id))
            }
        } else {
            iconView
        }
    }

    @ViewBuilder
    private var iconView: some View {
        if let iconURL = content.iconURL {
            IconView(url: iconURL, size: CGSize(bothDimensions: 24)) {
                Color.clear
            }
        }
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: 8) {
        StandaloneCallToActionMarketingBannerView(
            viewModel: CallToActionMarketingBannerViewModel(
                id: 1,
                title: "USD to USDC 1:1 with zero-fee",
                buttonTitle: "Join waitlist",
                isGlowing: true,
                link: URL(string: "tangem://support")!,
                isDismissible: false,
                content: .init(subtitle: "Not available in your region yet", iconURL: nil)
            ),
            onAction: { _ in }
        )

        StandaloneCallToActionMarketingBannerView(
            viewModel: CallToActionMarketingBannerViewModel(
                id: 2,
                title: "USD to USDC 1:1 with zero-fee",
                buttonTitle: "Join waitlist",
                isGlowing: false,
                link: URL(string: "tangem://support")!,
                isDismissible: true,
                content: .init(subtitle: nil, iconURL: nil)
            ),
            onAction: { _ in }
        )
    }
    .padding(16)
}
