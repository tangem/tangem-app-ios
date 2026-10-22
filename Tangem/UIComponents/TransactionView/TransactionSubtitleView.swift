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
        HStack(spacing: 4) {
            prefixView
            ownerView
        }
        .lineLimit(1)
    }

    private var prefixView: some View {
        Text(direction.localizedPrefix)
            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
    }

    @ViewBuilder
    private var ownerView: some View {
        switch owner {
        case .accountInCurrentWallet(let name, let icon),
             .accountInOtherWallet(let name, let icon):
            HStack(spacing: 4) {
                AccountIconView(data: icon)
                    .settings(.smallSized)
                Text(name)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textPrimary)
                    .lineLimit(1)
                    .accessibilityIdentifier(accessibilityIdentifier)
            }

        case .wallet(let name, _, let thumbnailType):
            HStack(spacing: 4) {
                Text(name)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textPrimary)
                    .lineLimit(1)
                    .accessibilityIdentifier(accessibilityIdentifier)

                if let thumbnailType {
                    MiniatureWalletView(type: thumbnailType)
                        .frame(width: glyphSize, height: glyphSize)
                }
            }

        case .contact(let name, let icon, _):
            HStack(spacing: 4) {
                AddressBookContactNameIconView(viewData: icon, size: 16)

                Text(name)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textPrimary)
                    .lineLimit(1)
                    .accessibilityIdentifier(accessibilityIdentifier)
            }

        case .unresolved(let short, _, let blockiesImage):
            HStack(spacing: 4) {
                addressBlockies(image: blockiesImage)
                Text(short)
                    .style(DesignSystem.Font.captionMediumToken, color: addressColor)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .accessibilityIdentifier(accessibilityIdentifier)
            }
        }
    }

    private var addressColor: Color {
        isAddressEmphasized ? DesignSystem.Color.textPrimary : DesignSystem.Color.textSecondary
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
                .fill(DesignSystem.Color.bgSecondary)
                .frame(width: glyphSize, height: glyphSize)
        }
    }
}

/// Renders `to: ⬤ Aave` on Supply and Withdraw, `from: ⬤ Merkl` on an incentive claim — the yield provider
/// standing in for a counterparty address.
struct TransactionProviderSubtitleView: View {
    let direction: TransactionDisplayModel.Direction
    let provider: TransactionDisplayModel.YieldProvider
    var accessibilityIdentifier: String? = nil

    @ScaledMetric private var glyphSize: CGFloat = 16

    var body: some View {
        HStack(spacing: 4) {
            Text(direction.localizedPrefix)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)

            logo
                .resizable()
                .frame(width: glyphSize, height: glyphSize)
                .clipShape(Circle())

            Text(name)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textPrimary)
                .accessibilityIdentifier(accessibilityIdentifier)
        }
        .lineLimit(1)
    }

    private var logo: Image {
        switch provider {
        case .aave: Assets.YieldModule.yieldModuleAaveLogo.image
        case .merkl: Assets.YieldModule.yieldModuleMerklLogo.image
        }
    }

    private var name: String {
        switch provider {
        case .aave: Localization.yieldModuleProvider
        case .merkl: Localization.yieldModuleIncentivesProvider
        }
    }
}
