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
    @IgnoredEquatable var onCopy: (() -> Void)? = nil
}

struct TransactionDetailsAddressView: View {
    let data: TransactionDetailsAddressViewData

    var body: some View {
        TangemRow(title: title, subtitle: data.label)
            .lineOrder(.secondaryFirst)
            .start { startIcon }
            .end { endAccessory }
            .background(
                DesignSystem.Color.bgTertiary,
                in: RoundedRectangle(cornerRadius: 24)
            )
    }

    private var title: String {
        data.actor.displayName
    }

    @ViewBuilder
    private var startIcon: some View {
        switch data.actor {
        case .address(_, let blockiesImage):
            AddressBlockiesIconView(viewData: blockiesImage)
        case .contact(_, let icon):
            AddressBookContactNameIconView(viewData: icon)
        case .account(_, let icon), .accountInWallet(_, let icon, _):
            AccountIconView(data: icon, settings: .defaultSized)
        case .wallet:
            EmptyView()
        }
    }

    @ViewBuilder
    private var endAccessory: some View {
        if let onCopy = data.onCopy {
            Button(action: onCopy) {
                DesignSystem.Icons.Copy.regular20.image
                    .renderingMode(.template)
                    .frame(size: CGSize(bothDimensions: 20))
                    .foregroundStyle(DesignSystem.Color.iconSecondary)
                    .padding(8)
                    .background(Circle().fill(DesignSystem.Color.bgOpaquePrimary))
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Previews

#Preview("Counterparty actors") {
    VStack(spacing: 16) {
        TransactionDetailsAddressView(data: .init(
            label: "From address",
            actor: .address(short: "33Bd321fS...ga21412B", blockiesImage: AddressBlockiesIconViewData(image: nil)),
            onCopy: {}
        ))

        TransactionDetailsAddressView(data: .init(
            label: "Recipient",
            actor: .contact(name: "Alice", AddressBookContactNameIconViewData(letter: "A", color: .blue)),
            onCopy: {}
        ))

        TransactionDetailsAddressView(data: .init(
            label: "To",
            actor: .account(name: "Family", icon: .composite(backgroundColor: .purple, nameMode: .letter("F")))
        ))

        TransactionDetailsAddressView(data: .init(
            label: "To",
            actor: .accountInWallet(accountName: "Main", accountIcon: .composite(backgroundColor: .green, nameMode: .letter("M")), walletName: "My Wallet")
        ))

        TransactionDetailsAddressView(data: .init(
            label: "To",
            actor: .wallet(name: "My Wallet")
        ))
    }
    .padding(16)
    .background(DesignSystem.Color.bgSecondary)
}
