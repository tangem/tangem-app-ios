//
//  AddFundsView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemLocalization

struct AddFundsView: View {
    @ObservedObject var viewModel: AddFundsViewModel

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.top, 64)

            Spacer()

            VStack(spacing: 8) {
                actionRow(
                    icon: Assets.Glyphs.walletNew,
                    title: Localization.commonBuy,
                    subtitle: Localization.addfundsBuyRowDescription,
                    action: viewModel.onBuy
                )
                .defaultRoundedBackground(with: Colors.Background.action, verticalPadding: 0, horizontalPadding: 0)

                actionRow(
                    icon: Assets.exchangeMini,
                    title: Localization.commonSwap,
                    subtitle: Localization.addfundsSwapRowDescription,
                    action: viewModel.onSwap
                )
                .defaultRoundedBackground(with: Colors.Background.action, verticalPadding: 0, horizontalPadding: 0)

                actionRow(
                    icon: Assets.qrCode,
                    title: Localization.commonReceive,
                    subtitle: Localization.addfundsReceiveRowDescription,
                    action: viewModel.onReceive
                )
                .defaultRoundedBackground(with: Colors.Background.action, verticalPadding: 0, horizontalPadding: 0)
            }
            .padding(.bottom, 24)

            MainButton(settings: .init(
                title: Localization.commonGoToToken,
                style: .secondary,
                size: .default,
                action: viewModel.onGoToToken
            ))
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .padding(.top, 12)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Colors.Background.tertiary.ignoresSafeArea())
        .navigationTitle(Localization.commonAddToken)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            NavigationToolbarButton.close(placement: .topBarTrailing, action: viewModel.onClose)
        }
    }

    private var header: some View {
        VStack(spacing: 20) {
            TokenIcon(
                tokenIconInfo: viewModel.tokenIconInfo,
                size: .init(bothDimensions: 96)
            )

            VStack(spacing: 4) {
                Text(viewModel.fiatBalanceText)
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(Colors.Text.primary1)

                Text(viewModel.cryptoBalanceText)
                    .style(Fonts.Regular.body, color: Colors.Text.tertiary)
            }
        }
    }

    private func actionRow(icon: ImageType, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                GetTokenActionRowView(icon: icon, title: title, subtitle: subtitle)

                Assets.chevron.image
                    .renderingMode(.template)
                    .foregroundStyle(Colors.Icon.informative)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
        }
    }
}
