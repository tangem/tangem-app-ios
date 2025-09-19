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
        .buttonStyle(.plain)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 14) {
            topView

            bottomView
                // Icon size + padding
                .padding(.leading, 36 + 12)
        }
        .padding(.all, 14)
        .contentShape(Rectangle())
    }

    private var topView: some View {
        HStack(spacing: 12) {
            OnrampPaymentMethodIconView(url: viewModel.paymentMethod.iconURL)
                .accessibilityIdentifier(OnrampAccessibilityIdentifiers.paymentMethodIcon(id: viewModel.paymentMethod.id))

            titleView

            Spacer(minLength: 0)
        }
        .infinityFrame(axis: .horizontal)
    }

    private var titleView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.paymentMethod.name)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                .lineLimit(1)
                .accessibilityIdentifier(OnrampAccessibilityIdentifiers.paymentMethodName(id: viewModel.paymentMethod.id))

            HStack(spacing: 4) {
                // AttributedString
                Text(viewModel.amountFormatted)

                OnrampAmountBadge(badge: viewModel.amount.badge)
            }
        }
    }

    private var bottomView: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                Assets.stakingMiniIcon.image
                    .renderingMode(.template)
                    .resizable()
                    .foregroundStyle(Colors.Icon.informative)
                    .frame(width: 10, height: 10)

                Text(viewModel.providersFormatted)
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

                Text(viewModel.timeFormatted)
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
