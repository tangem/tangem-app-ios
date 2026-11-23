//
//  SettingsUserWalletRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI
import TangemAccessibilityIdentifiers

struct SettingsUserWalletRowView: View {
    @ObservedObject var viewModel: SettingsUserWalletRowViewModel

    var body: some View {
        SwiftUI.Button(action: viewModel.tapAction) {
            content
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(WalletSettingsAccessibilityIdentifiers.walletSettingsButton(name: viewModel.name))
    }

    @ViewBuilder
    private var content: some View {
        RowWithLeadingAndTrailingIcons(
            leadingIcon: { icon },
            content: { textViews },
            trailingIcon: {
                if viewModel.isUserWalletBackupNeeded {
                    Assets.redCircleWarning.image
                }

                Assets.chevron.image
            }
        )
        .infinityFrame(axis: .horizontal, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var icon: some View {
        UserWalletIconView(icon: viewModel.icon, size: 36)
    }

    private var textViews: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Text(viewModel.name)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

                if viewModel.hasSeedPhrase {
                    Badge(label: Localization.detailsWalletSeedBadge, accessibilityLabel: Localization.commonSeedPhrase)
                        .size(.x4)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }

            HStack(spacing: 4) {
                Text(viewModel.cardSetLabel)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .layoutPriority(1)

                if viewModel.balanceState != .empty {
                    Text(AppConstants.dotSign)
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)

                    LoadableBalanceView(
                        state: viewModel.balanceState,
                        style: .init(font: DesignSystem.Font.captionMediumToken, textColor: DesignSystem.Color.textSecondary),
                        loader: .init(size: CGSize(width: 40, height: 12))
                    )
                }
            }
            .lineLimit(1)
            .truncationMode(.tail)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Previews

#Preview("SettingsUserWalletRowView") {
    let cardSetLabel = UserWalletModelMock().config.cardSetLabel

    ZStack {
        DesignSystem.Color.bgPrimary.ignoresSafeArea()

        VStack {
            SettingsUserWalletRowView(
                viewModel: .init(
                    name: "My wallet",
                    cardSetLabel: cardSetLabel,
                    hasSeedPhrase: false,
                    isUserWalletBackupNeeded: false,
                    isUserWalletLocked: false,
                    userWalletUpdatePublisher: .just(output: .nameDidChange(name: "My wallet")),
                    totalBalancePublisher: .just(output: .loading(cached: .none)),
                    icon: .loadable(CardImageProviderMock()),
                    tapAction: {}
                )
            )

            SettingsUserWalletRowView(
                viewModel: .init(
                    name: "My wallet",
                    cardSetLabel: cardSetLabel,
                    hasSeedPhrase: true,
                    isUserWalletBackupNeeded: false,
                    isUserWalletLocked: false,
                    userWalletUpdatePublisher: .just(output: .nameDidChange(name: "My wallet")),
                    totalBalancePublisher: .just(output: .failed(cached: .none, failedItems: [])),
                    icon: .loadable(CardImageProviderMock()),
                    tapAction: {}
                )
            )

            SettingsUserWalletRowView(
                viewModel: .init(
                    name: "This is my second wallet with a very long name",
                    cardSetLabel: cardSetLabel,
                    hasSeedPhrase: true,
                    isUserWalletBackupNeeded: false,
                    isUserWalletLocked: false,
                    userWalletUpdatePublisher: .empty,
                    totalBalancePublisher: .just(output: .loaded(balance: 123456789.99)),
                    icon: .loadable(CardImageProviderMock()),
                    tapAction: {}
                )
            )

            SettingsUserWalletRowView(
                viewModel: .init(
                    name: "Locked wallet",
                    cardSetLabel: cardSetLabel,
                    hasSeedPhrase: false,
                    isUserWalletBackupNeeded: true,
                    isUserWalletLocked: true,
                    userWalletUpdatePublisher: .just(output: .nameDidChange(name: "Locked wallet")),
                    totalBalancePublisher: .just(output: .failed(cached: .none, failedItems: [])),
                    icon: .loadable(CardImageProviderMock()),
                    tapAction: {}
                )
            )
        }
        .padding()
    }
}
