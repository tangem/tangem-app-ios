//
//  OnrampOfferView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils
import TangemAccessibilityIdentifiers

struct OnrampOfferView: View {
    @Environment(\.colorScheme) private var colorScheme

    let viewModel: OnrampOfferViewModel
    var cardBackground: Color = DesignSystem.Color.bgSecondary

    private static let cornerRadius: CGFloat = 24

    var body: some View {
        VStack(spacing: 0) {
            cardContent
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
                        .fill(cardBackground)
                )
                .if(viewModel.isNativePayment) { card in
                    card.glowRing(size: .card(cornerRadius: Self.cornerRadius), isVisible: isBuyButtonEnabled)
                }
                .zIndex(1)

            if let linkedBanner = viewModel.linkedBanner {
                LinkedMarketingBannerView(viewModel: linkedBanner, cardCornerRadius: Self.cornerRadius)
            }
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            topView

            VStack(alignment: .leading, spacing: 12) {
                bottomView

                if let legalNotice = viewModel.legalNotice {
                    Separator(height: .minimal, color: DesignSystem.Color.borderSecondary)
                    legalNoticeView(legalNotice)
                }
            }
            .padding(.top, 12)
        }
    }

    private var topView: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                title

                amount
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            buyButton
        }
    }

    @ViewBuilder
    private var title: some View {
        switch viewModel.title {
        case .text(let text):
            Text(text)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textPrimary)

        case .great:
            Text(Localization.expressProviderGreatRate)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textStatusInfo)

        case .bestRate:
            titleWithIcon(
                DesignSystem.Icons.Star.filled16,
                text: Localization.expressProviderBestRate,
                iconColor: DesignSystem.Color.iconStatusInfo,
                textColor: DesignSystem.Color.textStatusInfo
            )

        case .fastest:
            titleWithIcon(
                DesignSystem.Icons.Lightning.regular12,
                text: Localization.onrampOfferTypeFastet,
                iconColor: DesignSystem.Color.iconStatusWarning,
                textColor: DesignSystem.Color.textStatusWarning
            )
        }
    }

    private func titleWithIcon(_ icon: ImageType, text: String, iconColor: Color, textColor: Color) -> some View {
        HStack(spacing: 4) {
            icon.image
                .resizable()
                .renderingMode(.template)
                .frame(width: 12, height: 12)
                .foregroundStyle(iconColor)

            Text(text)
                .style(DesignSystem.Font.captionMediumToken, color: textColor)
        }
    }

    private var amount: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 4) {
                amountText
                amountAccessories
            }

            VStack(alignment: .leading, spacing: 4) {
                amountText
                HStack(spacing: 4) { amountAccessories }
            }
        }
    }

    private var amountText: some View {
        Text(viewModel.amount.formatted)
            .style(
                DesignSystem.Font.bodyMediumToken,
                color: viewModel.isAvailable ? DesignSystem.Color.textPrimary : DesignSystem.Color.textSecondary
            )
            .accessibilityIdentifier(OnrampAccessibilityIdentifiers.providerAmount(name: viewModel.provider.name))
    }

    @ViewBuilder
    private var amountAccessories: some View {
        OnrampAmountBadge(badge: viewModel.amount.badge)
            .accessibilityIdentifier(OnrampAccessibilityIdentifiers.providerAmountBadge(name: viewModel.provider.name))

        if let infoAction = viewModel.amount.infoAction {
            SwiftUI.Button(action: infoAction) {
                DesignSystem.Icons.Info.regular16.image
                    .renderingMode(.template)
                    .foregroundStyle(DesignSystem.Color.iconSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(OnrampAccessibilityIdentifiers.providerInfoButton(name: viewModel.provider.name))
        }
    }

    private func legalNoticeView(_ notice: OnrampOfferViewModel.LegalNotice) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Self.makeLegalNoticeAttributedString(notice))

            Text(Localization.onrampNativePaymentIdentityVerification(notice.providerName))
        }
        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private static func makeLegalNoticeAttributedString(
        _ notice: OnrampOfferViewModel.LegalNotice
    ) -> AttributedString {
        let tos = Localization.commonTermsOfUse
        let privacy = Localization.commonPrivacyPolicy

        var attributed = AttributedString(
            Localization.onrampNativePaymentLegalNotice(notice.providerName, tos, privacy)
        )

        formatLink(in: &attributed, text: tos, url: notice.termsOfUse)
        formatLink(in: &attributed, text: privacy, url: notice.privacyPolicy)
        return attributed
    }

    private static func formatLink(in attributed: inout AttributedString, text: String, url: URL?) {
        guard let url, let range = attributed.range(of: text) else { return }
        attributed[range].link = url
        attributed[range].foregroundColor = DesignSystem.Color.textStatusInfo
    }

    private var bottomView: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: .zero) {
                HStack(spacing: 8) {
                    timeView
                    providerView
                }

                Spacer(minLength: 8)

                trailingBottomView
            }

            VStack(alignment: .leading, spacing: 8) {
                timeView
                providerView
                trailingBottomView
            }
        }
    }

    @ViewBuilder
    private var buyButton: some View {
        switch viewModel.buyAction {
        case .button(let action):
            TangemUI.Button(label: Localization.commonBuy, accessibilityLabel: nil, action: action)
                .size(.x10)
                .styleType(.primary)
                .enabled(isBuyButtonEnabled)
                .fixedSize()
                .accessibilityIdentifier(OnrampAccessibilityIdentifiers.providerBuyButton(name: viewModel.provider.name))
        case .nativeApplePay(let onTap):
            PKPaymentButtonRepresentable(action: onTap)
                .frame(width: 66, height: 40)
                .clipShape(Capsule())
                .disabled(!isBuyButtonEnabled)
                .opacity(isBuyButtonEnabled ? 1 : 0.4)
                .accessibilityIdentifier(OnrampAccessibilityIdentifiers.providerNativeApplePayButton(name: viewModel.provider.name))
        }
    }

    private var isBuyButtonEnabled: Bool {
        viewModel.isAvailable && viewModel.isBuyEnabled
    }

    private var timeView: some View {
        HStack(spacing: 2) {
            DesignSystem.Icons.Clock.regular16.image
                .renderingMode(.template)
                .foregroundStyle(DesignSystem.Color.iconSecondary)

            Text(viewModel.provider.timeFormatted)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
        }
    }

    private var providerView: some View {
        HStack(spacing: 2) {
            if let iconURL = viewModel.provider.iconURL {
                IconView(url: iconURL, size: CGSize(width: 16, height: 16), forceKingfisher: false)
                    .clipShape(Circle())
                    .accessibilityHidden(true)
            }

            Text(Localization.onrampViaProvider(viewModel.provider.name))
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
        }
    }

    @ViewBuilder
    private var trailingBottomView: some View {
        if viewModel.isNativePayment {
            Text(Localization.onrampPaymentMethodSubtitle)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
        } else {
            HStack(spacing: 4) {
                Text(Localization.onrampPayWith)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)

                IconView(url: viewModel.provider.paymentType.themedImageURL(isDark: colorScheme == .dark), size: .height(16)) {
                    Shimmer().variant(.custom(width: 30, height: 16, cornerRadius: 6))
                }
                .foregroundStyle(DesignSystem.Color.iconSecondary)
            }
        }
    }
}
