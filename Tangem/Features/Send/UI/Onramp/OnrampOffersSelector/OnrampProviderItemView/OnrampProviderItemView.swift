//
//  OnrampProviderItemView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization
import TangemAccessibilityIdentifiers

struct OnrampProviderItemView: View {
    let viewModel: OnrampProviderItemViewModel

    var body: some View {
        Button(action: viewModel.action) {
            content
                .defaultRoundedBackground(
                    with: Colors.Background.action,
                    verticalPadding: .zero,
                    horizontalPadding: .zero
                )
        }
        .accessibilityIdentifier(OnrampAccessibilityIdentifiers.paymentMethodCard)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 14) {
            topView

            if let providersInfo = viewModel.providersInfo {
                availableOffers(providers: providersInfo)
                    // Icon size + padding
                    .padding(.leading, 36 + 12)
            }
        }
        .padding(.all, 14)
        .contentShape(Rectangle())
    }

    private var topView: some View {
        HStack(spacing: 12) {
            OnrampPaymentMethodIconView(url: viewModel.paymentMethod.iconURL)
                .opacity(viewModel.isAvailable ? 1 : 0.5)
                .accessibilityIdentifier(OnrampAccessibilityIdentifiers.paymentMethodIcon(id: viewModel.paymentMethod.id))

            titleView

            Spacer(minLength: 0)
        }
        .infinityFrame(axis: .horizontal)
    }

    private var titleView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.paymentMethod.name)
                .style(Fonts.Bold.subheadline, color: viewModel.isAvailable ? Colors.Text.primary1 : Colors.Text.tertiary)
                .lineLimit(1)
                .accessibilityIdentifier(OnrampAccessibilityIdentifiers.paymentMethodName(id: viewModel.paymentMethod.id))

            amountView
        }
    }

    @ViewBuilder
    private var amountView: some View {
        switch viewModel.amountType {
        case .availableFrom(let amount):
            Text(Localization.onrampProviderMinAmount(amount))
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                .accessibilityIdentifier(OnrampAccessibilityIdentifiers.providerAmount(name: viewModel.paymentMethod.id))
        case .availableUpTo(let amount):
            Text(Localization.onrampProviderMaxAmount(amount))
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                .accessibilityIdentifier(OnrampAccessibilityIdentifiers.providerAmount(name: viewModel.paymentMethod.id))
        case .available(let amount):
            HStack(spacing: 4) {
                Text(amount.attributedFormatted)
                    .accessibilityIdentifier(OnrampAccessibilityIdentifiers.providerAmount(name: viewModel.paymentMethod.id))

                OnrampAmountBadge(badge: amount.badge)
            }
        }
    }

    private func availableOffers(providers: OnrampProviderItemViewModel.ProvidersInfo) -> some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                Assets.stakingMiniIcon.image
                    .renderingMode(.template)
                    .resizable()
                    .foregroundStyle(Colors.Icon.informative)
                    .frame(width: 10, height: 10)

                Text(providers.providersFormatted)
                    .style(Fonts.Regular.caption2, color: Colors.Text.tertiary)
            }
            .padding(4)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Colors.Stroke.primary, lineWidth: 1)
            )

            HStack(spacing: 4) {
                Assets.Express.providerTimeIconMini.image
                    .renderingMode(.template)
                    .resizable()
                    .foregroundStyle(Colors.Icon.informative)
                    .frame(width: 10, height: 10)

                Text(providers.timeFormatted)
                    .style(Fonts.Regular.caption2, color: Colors.Text.tertiary)
            }
            .padding(4)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Colors.Stroke.primary, lineWidth: 1)
            )
        }
    }
}
