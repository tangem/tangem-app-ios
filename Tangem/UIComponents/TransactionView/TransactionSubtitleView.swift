//
//  TransactionSubtitleView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccounts
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

/// Renders the redesigned subtitle line: direction prefix (`to:` / `from:`) + structured owner.
struct TransactionSubtitleView: View {
    let direction: TransactionDisplayModel.Direction
    let owner: TransactionViewModel.SubtitleOwner
    var accessibilityIdentifier: String? = nil
    var isAddressEmphasized: Bool = false

    @ScaledMetric private var glyphSize: CGFloat = 16

    var body: some View {
        HStack(spacing: .unit(.x1)) {
            prefixView
            ownerView
        }
        .lineLimit(1)
    }

    private var prefixView: some View {
        Text(direction.localizedPrefix)
            .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.tertiary)
    }

    @ViewBuilder
    private var ownerView: some View {
        switch owner {
        case .accountInCurrentWallet(let name, let icon),
             .accountInOtherWallet(let name, let icon):
            HStack(spacing: .unit(.x1)) {
                AccountIconView(data: icon)
                    .settings(.smallSized)
                Text(name)
                    .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.primary)
                    .lineLimit(1)
                    .accessibilityIdentifier(accessibilityIdentifier)
            }

        case .wallet(let name, _, let thumbnailType):
            HStack(spacing: .unit(.x1)) {
                Text(name)
                    .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.primary)
                    .lineLimit(1)
                    .accessibilityIdentifier(accessibilityIdentifier)

                if let thumbnailType {
                    MiniatureWalletView(type: thumbnailType)
                        .frame(width: glyphSize, height: glyphSize)
                }
            }

        case .contact(let name, let icon, _):
            HStack(spacing: .unit(.x1)) {
                AddressBookContactNameIconView(viewData: icon, size: 16)

                Text(name)
                    .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.primary)
                    .lineLimit(1)
                    .accessibilityIdentifier(accessibilityIdentifier)
            }

        case .unresolved(let short, _, let blockiesImage):
            HStack(spacing: .unit(.x1)) {
                addressBlockies(image: blockiesImage)
                Text(short)
                    .style(Font.Tangem.Caption12.semibold, color: addressColor)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .accessibilityIdentifier(accessibilityIdentifier)
            }
        }
    }

    private var addressColor: Color {
        isAddressEmphasized ? .Tangem.Text.Neutral.primary : .Tangem.Text.Neutral.tertiary
    }

    @ViewBuilder
    private func addressBlockies(image: UIImage?) -> some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .interpolation(.none)
                .frame(width: glyphSize, height: glyphSize)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(Color.Tangem.Surface.level3)
                .frame(width: glyphSize, height: glyphSize)
        }
    }
}

/// Renders `to: ⬤ Aave` — the yield provider standing in for a counterparty on the Supply and Withdraw rows.
struct TransactionProviderSubtitleView: View {
    let direction: TransactionDisplayModel.Direction
    var accessibilityIdentifier: String? = nil

    @ScaledMetric private var glyphSize: CGFloat = 16

    var body: some View {
        HStack(spacing: .unit(.x1)) {
            Text(direction.localizedPrefix)
                .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.tertiary)

            Assets.YieldModule.yieldModuleAaveLogo.image
                .resizable()
                .frame(width: glyphSize, height: glyphSize)
                .clipShape(Circle())

            Text(Localization.yieldModuleProvider)
                .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.primary)
                .accessibilityIdentifier(accessibilityIdentifier)
        }
        .lineLimit(1)
    }
}
