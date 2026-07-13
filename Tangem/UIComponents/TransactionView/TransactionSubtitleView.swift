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
import TangemUIUtils

/// Renders the redesigned subtitle line: direction prefix (`to:` / `from:`) + structured owner.
/// View owns the punctuation localisation so the resolver/mapper layer doesn't need locale-aware
/// glue (avoids the `commonTo + ":"` concat-locale hazard).
struct TransactionSubtitleView: View {
    let direction: TransactionDisplayModel.Direction
    let owner: TransactionViewModel.SubtitleOwner
    var accessibilityIdentifier: String? = nil

    @ScaledMetric private var glyphSize: CGFloat = 16

    var body: some View {
        HStack(spacing: .unit(.x1)) {
            prefixView
            ownerView
        }
        .lineLimit(1)
    }

    private var prefixView: some View {
        Text(directionPrefix)
            .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.tertiary)
    }

    @ViewBuilder
    private var ownerView: some View {
        switch owner {
        case .account(let name, let icon):
            HStack(spacing: .unit(.x1)) {
                AccountIconView(data: icon)
                    .settings(.smallSized)
                Text(name)
                    .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.primary)
                    .lineLimit(1)
                    .accessibilityIdentifier(accessibilityIdentifier)
            }

        case .wallet(let name):
            Text(name)
                .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.primary)
                .lineLimit(1)
                .accessibilityIdentifier(accessibilityIdentifier)

        case .accountInWallet(let accountName, let accountIcon, let walletName):
            HStack(spacing: .unit(.x1)) {
                AccountIconView(data: accountIcon)
                    .settings(.smallSized)
                Text(accountName)
                    .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.primary)
                    .lineLimit(1)
                    .accessibilityIdentifier(accessibilityIdentifier)
                Text(Localization.commonIn)
                    .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.tertiary)
                Text(walletName)
                    .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.primary)
                    .lineLimit(1)
            }

        case .unresolved(let short, _, let blockiesImage):
            HStack(spacing: .unit(.x1)) {
                addressBlockies(image: blockiesImage)
                Text(short)
                    .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .accessibilityIdentifier(accessibilityIdentifier)
            }
        }
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

    /// Recovered from the `"from: %@"` / `"to: %@"` localised templates by formatting them with
    /// an empty value and stripping trailing whitespace — keeps the punctuation locale-correct
    /// without adding new string keys.
    private var directionPrefix: String {
        let template = switch direction {
        case .incoming: Localization.transactionHistoryTransactionFromAddress("")
        case .outgoing: Localization.transactionHistoryTransactionToAddress("")
        }
        return template.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
