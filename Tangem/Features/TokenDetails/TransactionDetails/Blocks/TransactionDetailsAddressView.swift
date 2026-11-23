//
//  TransactionDetailsAddressView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccounts
import TangemAssets
import TangemUI
import TangemUIUtils
import TangemFoundation

struct TransactionDetailsAddressViewData: Equatable {
    /// Row label (subtitle), e.g. "From address" / "Recipient" / "From" / "To".
    let label: String
    let actor: TransactionDetailsActor
    let copyAction: TransactionDetailsViewModel.ViewAction?
    @IgnoredEquatable var walletIcon: UserWalletIcon?
}

struct TransactionDetailsAddressView: View {
    let data: TransactionDetailsAddressViewData
    let onAction: (TransactionDetailsViewModel.ViewAction) -> Void

    var body: some View {
        Row(title: title, subtitle: data.label)
            .lineOrder(.secondaryFirst)
            .truncationModes(RowTruncationModes(title: data.actor.displayNameTruncationMode))
            .start { startIcon }
            .ifLet(data.copyAction) { view, action in
                view.onTap { onAction(action) }
            }
            .background(DesignSystem.Color.bgTertiary)
            .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var title: String {
        data.actor.displayName
    }

    @ViewBuilder
    private var startIcon: some View {
        switch data.actor {
        case .address(_, let blockiesImage), .validator(_, let blockiesImage):
            AddressBlockiesIconView(viewData: blockiesImage)
        case .contact(_, let icon):
            AddressBookContactNameIconView(viewData: icon)
        case .account(_, let icon):
            AccountIconView(data: icon, settings: .defaultSized)
        case .wallet:
            if let walletIcon = data.walletIcon {
                WalletCounterpartyIconView(icon: walletIcon)
            } else {
                EmptyView()
            }
        }
    }
}

// MARK: - Wallet icon

private struct WalletCounterpartyIconView: View {
    let icon: UserWalletIcon

    @ScaledMetric private var side: CGFloat = 36

    var body: some View {
        UserWalletIconView(icon: icon, size: side)
    }
}

// MARK: - Previews

#Preview("Counterparty actors") {
    VStack(spacing: 16) {
        TransactionDetailsAddressView(
            data: .init(
                label: "From address",
                actor: .address("33Bd321fS2p2o8Bk7mQwXeATkLQ3B36Yv2p21cEZga21412B", blockiesImage: AddressBlockiesIconViewData(image: nil)),
                copyAction: .copy(value: "33Bd321fS2p2o8Bk7mQwXeATkLQ3B36Yv2p21cEZga21412B", toast: "Copied", kind: .address),
                walletIcon: nil
            ),
            onAction: { _ in }
        )

        TransactionDetailsAddressView(
            data: .init(
                label: "Recipient",
                actor: .contact(name: "Alice", AddressBookContactNameIconViewData(letter: "A", color: .blue)),
                copyAction: .copy(value: "Alice", toast: "Copied", kind: .address),
                walletIcon: nil
            ),
            onAction: { _ in }
        )

        TransactionDetailsAddressView(
            data: .init(
                label: "To",
                actor: .account(name: "Family", icon: .composite(backgroundColor: .purple, nameMode: .letter("F"))),
                copyAction: nil,
                walletIcon: nil
            ),
            onAction: { _ in }
        )

        TransactionDetailsAddressView(
            data: .init(
                label: "To",
                actor: .wallet(name: "My Wallet"),
                copyAction: nil,
                walletIcon: nil
            ),
            onAction: { _ in }
        )
    }
    .padding(16)
    .background(DesignSystem.Color.bgSecondary)
}
