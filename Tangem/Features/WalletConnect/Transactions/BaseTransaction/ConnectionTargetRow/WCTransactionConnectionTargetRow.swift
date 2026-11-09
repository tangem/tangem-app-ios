//
//  WCTransactionConnectionTargetRow.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemAccounts

struct WCTransactionConnectionTargetRow: View {
    let kind: WCTransactionConnectionTargetKind

    var body: some View {
        switch kind {
        case .wallet(let name):
            makeWalletRow(name: name)

        case .account(let viewData):
            makeAccountRow(viewData)
        }
    }

    private func makeWalletRow(name: String) -> some View {
        rowContent(label: Localization.wcCommonWallet) {
            Text(name)
                .style(Fonts.Regular.body, color: DesignSystem.Color.textSecondary)
        }
    }

    private func makeAccountRow(_ data: WCTransactionAccountRowViewData) -> some View {
        rowContent(label: Localization.commonAccount) {
            AccountInlineHeaderView(
                iconData: data.iconViewData,
                name: data.accountName
            )
            .iconSettings(.smallSized)
            .font(Fonts.Regular.body)
            .textColor(DesignSystem.Color.textSecondary)
        }
    }

    private func rowContent<Content: View>(
        label: String,
        @ViewBuilder trailing: () -> Content
    ) -> some View {
        HStack(spacing: 0) {
            Assets.Glyphs.walletNew.image
                .renderingMode(.template)
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundStyle(DesignSystem.Color.iconAccentBlue)
                .padding(.trailing, 8)

            Text(label)
                .style(Fonts.Regular.body, color: DesignSystem.Color.textPrimary)
                .padding(.trailing, 8)

            Spacer()

            trailing()
        }
        .lineLimit(1)
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
    }
}
