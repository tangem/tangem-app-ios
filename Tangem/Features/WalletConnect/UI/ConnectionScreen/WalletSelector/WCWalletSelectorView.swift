//
//  WCWalletSelectorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct WCWalletSelectorView: View {
    let selectedWalletId: String
    let userWalletModels: [UserWalletModel]
    let onTapAction: (UserWalletModel) -> Void
    let backAction: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            walletSelectorHeader
                .padding(.bottom, 22)

            ForEach(userWalletModels, id: \.userWalletId) { userWalletModel in
                WCWalletRowView(
                    viewModel: .init(
                        userWallet: userWalletModel,
                        tapAction: { onTapAction(userWalletModel) }
                    )
                )
                .padding(.init(top: 14, leading: 16, bottom: 14, trailing: 16))
                .background { selectionBorder(userWalletModel.userWalletId.stringValue) }

                if userWalletModel.userWalletId != userWalletModels.last?.userWalletId {
                    Divider()
                        .padding(.leading, 62)
                }
            }
        }
    }

    private var walletSelectorHeader: some View {
        HStack(alignment: .center) {
            Text("Choose wallet")
                .style(Fonts.Bold.headline, color: Colors.Text.primary1)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .leading, content: backButton)
        }
    }

    private func backButton() -> some View {
        Button(
            action: backAction,
            label: {
                ZStack {
                    Circle()
                        .foregroundStyle(Colors.Button.secondary)
                        .frame(size: .init(bothDimensions: 28))
                    Assets.WalletConnect.chevronRight.image
                        .renderingMode(.template)
                        .foregroundStyle(Colors.Icon.secondary)
                        .rotationEffect(.degrees(180))
                }
            }
        )
    }

    @ViewBuilder
    private func selectionBorder(_ userWalletModelId: String) -> some View {
        if selectedWalletId == userWalletModelId {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(style: .init(lineWidth: 1))
                    .foregroundStyle(Colors.Text.accent)
                RoundedRectangle(cornerRadius: 14)
                    .stroke(style: .init(lineWidth: 2.5))
                    .foregroundStyle(Colors.Text.accent.opacity(0.2))
                    .padding(-1)
            }
        }
    }
}
