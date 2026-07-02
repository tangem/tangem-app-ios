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
import TangemLocalization

struct TransactionDetailsAddressViewData: Equatable {
    /// Row label (subtitle), e.g. "From address" / "Recipient" / "From" / "To".
    let label: String
    let actor: Actor
    @IgnoredEquatable var onCopy: (() -> Void)? = nil

    enum Actor: Equatable {
        case address(short: String, blockiesImage: AddressBlockiesIconViewData)
        /// Saved address-book contact.
        case contact(name: String, AddressBookContactNameIconViewData)
        /// One of the users accounts (same wallet).
        case account(name: String, icon: AccountIconView.ViewData)
        /// An account in another of the users wallets.
        case accountInWallet(accountName: String, accountIcon: AccountIconView.ViewData, walletName: String)
        /// One of the users wallets (accounts not shown).
        case wallet(name: String)
    }
}

struct TransactionDetailsAddressView: View {
    let data: TransactionDetailsAddressViewData

    var body: some View {
        TangemRow(title: title, subtitle: data.label)
            .lineOrder(.secondaryFirst)
            .verticalAlignment(.center)
            .start { startIcon }
            .end { endAccessory }
            .background(
                DesignSystem.Color.bgTertiary,
                in: RoundedRectangle(cornerRadius: 24)
            )
    }

    private var title: String {
        switch data.actor {
        case .address(let short, _): short
        case .contact(let name, _): name
        case .account(let name, _): name
        // [REDACTED_TODO_COMMENT]
        case .accountInWallet(let accountName, _, let walletName): "\(accountName) \(Localization.commonIn) \(walletName)"
        case .wallet(let name): name
        }
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
