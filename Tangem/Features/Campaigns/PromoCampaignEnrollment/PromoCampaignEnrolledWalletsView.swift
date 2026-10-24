//
//  PromoCampaignEnrolledWalletsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct PromoCampaignEnrolledWalletsView: View {
    let wallets: [PromoCampaignEnrolledWalletViewModel]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(Localization.promoCampaignEnrolledWallets)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                .padding(.vertical, 12)
                .accessibilityAddTraits(.isHeader)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(wallets) { wallet in
                        WalletRow(viewModel: wallet)
                    }
                }
                .padding(.vertical, 8)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
            .frame(maxHeight: Constants.listMaxHeight)
            .background(DesignSystem.Color.bgTransparentPrimary)
            .cornerRadiusContinuous(Constants.cornerRadius)
        }
    }
}

// MARK: - WalletRow

private extension PromoCampaignEnrolledWalletsView {
    struct WalletRow: View {
        @ObservedObject var viewModel: PromoCampaignEnrolledWalletViewModel

        var body: some View {
            TangemUI.Row(title: viewModel.name, subtitle: viewModel.subtitle)
                .subtitleAccessory {
                    balance
                }
                .start {
                    PromoCampaignWalletImageView(imageProvider: viewModel.imageProvider, side: Constants.walletImageSide)
                }
        }

        @ViewBuilder
        private var balance: some View {
            if viewModel.balanceState != .empty {
                HStack(spacing: 4) {
                    Text(AppConstants.dotSign)
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)

                    LoadableBalanceView(
                        state: viewModel.balanceState,
                        style: .init(font: DesignSystem.Font.captionMediumToken, textColor: DesignSystem.Color.textSecondary),
                        loader: .init(size: Constants.balanceLoaderSize)
                    )
                }
            }
        }
    }
}

// MARK: - Constants

private enum Constants {
    static let cornerRadius: CGFloat = 20
    static let walletImageSide: CGFloat = 36
    static let listMaxHeight: CGFloat = 280
    static let balanceLoaderSize = CGSize(width: 40, height: 12)
}

// MARK: - Previews

#Preview {
    PromoCampaignEnrolledWalletsView(wallets: PromoCampaignEnrolledWalletViewModel.previewWallets)
        .padding(16)
        .background(DesignSystem.Color.bgPrimary)
}

extension PromoCampaignEnrollmentWallet {
    static let previewWallets: [PromoCampaignEnrollmentWallet] = [
        PromoCampaignEnrollmentWallet(
            name: "Main wallet",
            subtitle: "3 cards",
            imageProvider: CardImageProviderMock(),
            payout: Payout(
                address: "0x33Bd321fS9a0c4e1b7d2E5f8a6C3b0xxdSga21412B"
            )
        ),
        PromoCampaignEnrollmentWallet(
            name: "Multi Card",
            subtitle: "1 card",
            imageProvider: CardImageProviderMock(),
            payout: nil
        ),
    ]
}
