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
import TangemAccessibilityIdentifiers

struct OnrampOfferView: View {
    let viewModel: OnrampOfferViewModel

    var body: some View {
        VStack(spacing: 12) {
            topView

            if viewModel.legalNotice == nil {
                Separator(height: .minimal, color: Colors.Stroke.primary)
            }

            bottomView

            if let legalNotice = viewModel.legalNotice {
                Separator(height: .minimal, color: Colors.Stroke.primary)
                legalNoticeView(legalNotice)
            }
        }
        .defaultRoundedBackground(with: Colors.Background.action, verticalPadding: 12, horizontalPadding: 14)
        .environment(\.colorScheme, resolvedColorScheme)
        .opacity(viewModel.isAvailable ? 1 : 0.6)
    }

    /// Read synchronously to avoid an `@Environment(\.colorScheme)` subscription that leaks inside floating sheets.
    private var resolvedColorScheme: ColorScheme {
        let current: ColorScheme = UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .light
        guard viewModel.isNativePayment else { return current }
        return current == .light ? .dark : .light
    }

    private var topView: some View {
        HStack(spacing: 4) {
            VStack(alignment: .leading, spacing: 4) {
                title

                amount
            }

            Spacer(minLength: 8)

            buyButton
        }
    }

    @ViewBuilder
    private var title: some View {
        switch viewModel.title {
        case .text(let text):
            Text(text)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

        case .great:
            Text(Localization.expressProviderGreatRate)
                .style(Fonts.Bold.caption1, color: Colors.Text.accent)

        case .bestRate:
            HStack(alignment: .center, spacing: 4) {
                Assets.Express.bestRateStarIcon16.image
                    .renderingMode(.template)
                    .foregroundStyle(Colors.Icon.accent)

                Text(Localization.expressProviderBestRate)
                    .style(Fonts.Bold.caption1, color: Colors.Text.accent)
            }

        case .fastest:
            HStack(alignment: .center, spacing: 4) {
                Assets.Express.fastestIcon16.image
                    .renderingMode(.template)
                    .foregroundStyle(Colors.Icon.attention)

                Text(Localization.onrampOfferTypeFastet)
                    .style(Fonts.Bold.caption1, color: Colors.Text.attention)
            }
        }
    }

    private var amount: some View {
        HStack(spacing: 4) {
            Text(viewModel.amount.formatted)
                .style(
                    Fonts.Bold.callout,
                    color: viewModel.isAvailable ? Colors.Text.primary1 : Colors.Text.tertiary
                )
                .accessibilityIdentifier(OnrampAccessibilityIdentifiers.providerAmount(name: viewModel.provider.name))

            OnrampAmountBadge(badge: viewModel.amount.badge)

            if let infoAction = viewModel.amount.infoAction {
                Button(action: infoAction) {
                    Assets.infoCircle16.image
                        .renderingMode(.template)
                        .foregroundStyle(Colors.Icon.informative)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func legalNoticeView(_ notice: OnrampOfferViewModel.LegalNotice) -> some View {
        let attributed = Self.makeLegalNoticeAttributedString(notice)
        return Text(attributed)
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
        attributed.font = Fonts.Regular.caption1
        attributed.foregroundColor = Colors.Text.tertiary

        formatLink(in: &attributed, text: tos, url: notice.termsOfUse)
        formatLink(in: &attributed, text: privacy, url: notice.privacyPolicy)
        return attributed
    }

    private static func formatLink(in attributed: inout AttributedString, text: String, url: URL?) {
        guard let url, let range = attributed.range(of: text) else { return }
        attributed[range].link = url
        attributed[range].foregroundColor = Colors.Text.accent
    }

    private var bottomView: some View {
        HStack(spacing: .zero) {
            leadingBottomView

            Spacer(minLength: 8)

            trailingBottomView
        }
    }

    @ViewBuilder
    private var buyButton: some View {
        switch viewModel.buyAction {
        case .button(let action):
            CapsuleButton(title: Localization.commonBuy, action: action)
                .size(.medium)
                .style(.primary)
                .disabled(!viewModel.isAvailable)
        case .nativeApplePay(let onTap):
            PKPaymentButtonRepresentable(action: onTap)
                .frame(width: 66, height: 32)
                .clipShape(Capsule())
                .disabled(!viewModel.isAvailable)
        }
    }

    private var leadingBottomView: some View {
        HStack(spacing: 4) {
            HStack(spacing: 2) {
                Assets.Express.providerTimeIcon.image
                    .renderingMode(.template)
                    .foregroundStyle(Colors.Icon.informative)

                Text(viewModel.provider.timeFormatted)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
            }

            Text(AppConstants.dotSign)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

            Text(Localization.onrampViaProvider(viewModel.provider.name))
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
        }
    }

    @ViewBuilder
    private var trailingBottomView: some View {
        if viewModel.isNativePayment {
            Text(Localization.onrampPaymentMethodSubtitle)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
        } else {
            HStack(spacing: 4) {
                Text(Localization.onrampPayWith)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

                IconView(url: viewModel.provider.paymentType.image, size: .height(16)) {
                    SkeletonView()
                        .frame(width: 30, height: 16)
                        .cornerRadiusContinuous(6)
                }
                .foregroundStyle(Colors.Icon.secondary)
            }
        }
    }
}
