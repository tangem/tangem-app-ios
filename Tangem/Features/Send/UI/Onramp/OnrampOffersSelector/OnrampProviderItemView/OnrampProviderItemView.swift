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
        SwiftUI.Button(action: viewModel.action) {
            content
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(DesignSystem.Color.bgTransparentOnMaterialPrimary)
                )
                .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(OnrampAccessibilityIdentifiers.paymentMethodCard)
    }

    private var content: some View {
        HStack(alignment: .top, spacing: 12) {
            OnrampPaymentMethodIconView(
                lightURL: viewModel.paymentMethod.lightIconURL,
                darkURL: viewModel.paymentMethod.darkIconURL
            )
            .opacity(viewModel.isAvailable ? 1 : 0.5)
            .accessibilityIdentifier(OnrampAccessibilityIdentifiers.paymentMethodIcon(id: viewModel.paymentMethod.id))

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.paymentMethod.name)
                    .style(
                        DesignSystem.Font.bodyMediumToken,
                        color: viewModel.isAvailable ? DesignSystem.Color.textPrimary : DesignSystem.Color.textSecondary
                    )
                    .lineLimit(1)
                    .accessibilityIdentifier(OnrampAccessibilityIdentifiers.paymentMethodName(id: viewModel.paymentMethod.id))

                amountView

                if let providersInfo = viewModel.providersInfo {
                    availableOffers(providers: providersInfo)
                        .padding(.top, 4)
                }
            }
        }
    }

    @ViewBuilder
    private var amountView: some View {
        switch viewModel.amountType {
        case .availableFrom(let amount):
            Text(Localization.onrampProviderMinAmount(amount))
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                .accessibilityIdentifier(OnrampAccessibilityIdentifiers.providerAmount(name: viewModel.paymentMethod.id))
        case .availableUpTo(let amount):
            Text(Localization.onrampProviderMaxAmount(amount))
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                .accessibilityIdentifier(OnrampAccessibilityIdentifiers.providerAmount(name: viewModel.paymentMethod.id))
        case .available(let amount):
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 4) { availableAmount(amount) }
                VStack(alignment: .leading, spacing: 4) { availableAmount(amount) }
            }
        }
    }

    @ViewBuilder
    private func availableAmount(_ amount: OnrampProviderItemViewModel.Amount) -> some View {
        Text(amount.attributedFormatted)
            .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier(OnrampAccessibilityIdentifiers.providerAmount(name: viewModel.paymentMethod.id))

        OnrampAmountBadge(badge: amount.badge)
            .accessibilityIdentifier(OnrampAccessibilityIdentifiers.bestRateBadge(id: viewModel.paymentMethod.id))
    }

    private func availableOffers(providers: OnrampProviderItemViewModel.ProvidersInfo) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 4) { offerBadges(providers: providers) }
            VStack(alignment: .leading, spacing: 4) { offerBadges(providers: providers) }
        }
    }

    @ViewBuilder
    private func offerBadges(providers: OnrampProviderItemViewModel.ProvidersInfo) -> some View {
        TangemUI.Badge(label: providers.providersFormatted, accessibilityLabel: providers.providersFormatted)
            .size(.x4)
            .slotStart(DesignSystem.Icons.Stack.regular12)
            .accessibilityRemoveTraits(.isImage)
            .accessibilityAddTraits(.isStaticText)
            .accessibilityIdentifier(OnrampAccessibilityIdentifiers.providerCount(id: viewModel.paymentMethod.id))

        TangemUI.Badge(label: providers.timeFormatted, accessibilityLabel: providers.timeFormatted)
            .size(.x4)
            .slotStart(DesignSystem.Icons.Clock.regular12)
            .accessibilityRemoveTraits(.isImage)
            .accessibilityAddTraits(.isStaticText)
            .accessibilityIdentifier(OnrampAccessibilityIdentifiers.providerTime(id: viewModel.paymentMethod.id))
    }
}
