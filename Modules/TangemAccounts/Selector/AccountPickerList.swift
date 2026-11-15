//
//  AccountPickerList.swift
//  TangemAccounts
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

public struct AccountPickerList: View {
    private let sections: [AccountPickerUserWalletSection]
    private let isBalanceMasked: Bool
    private let onTap: (AccountPickerAccountItem) -> Void

    public init(sections: [AccountPickerUserWalletSection], isBalanceMasked: Bool, onTap: @escaping (AccountPickerAccountItem) -> Void) {
        self.sections = sections
        self.isBalanceMasked = isBalanceMasked
        self.onTap = onTap
    }

    public var body: some View {
        VStack(spacing: 8) {
            ForEach(sections) { section in
                SelectorCard {
                    if let header = section.header {
                        AccountPickerSectionHeader(header: header)
                    }

                    ForEach(section.accounts) { account in
                        AccountPickerAccountRow(item: account, isBalanceMasked: isBalanceMasked) {
                            onTap(account)
                        }
                    }
                }
            }
        }
    }
}

struct AccountPickerSectionHeader: View {
    let header: AccountPickerUserWalletSection.Header

    var body: some View {
        HStack(spacing: 4) {
            Text(header.name)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                .lineLimit(1)

            if let thumbnail = header.thumbnail {
                MiniatureWalletView(type: thumbnail)
                    .frame(width: 20, height: 20)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .padding(.horizontal, 16)
    }
}

struct AccountPickerAccountRow: View {
    let item: AccountPickerAccountItem
    let isBalanceMasked: Bool
    let onTap: () -> Void

    var body: some View {
        let row = Row(title: item.name)
            .start { AccountPickerAvatar(icon: item.icon) }
            .titleAccessory { titleBadge }
            .subtitleAccessory { subtitle }
            .end { end }

        if item.availability.isAvailable {
            row.onTap(action: onTap)
        } else {
            SwiftUI.Button(action: onTap) {
                row.disabled(true)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var titleBadge: some View {
        if let badge = item.badge {
            Badge(label: badge, accessibilityLabel: nil)
                .size(.x4)
                .variant(.tinted)
                .appearance(.neutral)
        }
    }

    private var subtitle: some View {
        HStack(spacing: 4) {
            if let subtitle = item.subtitle {
                Text(subtitle)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            }

            if let balance = item.balance {
                SelectorBalanceText(balance: balance, isMasked: isBalanceMasked)
            }
        }
    }

    @ViewBuilder
    private var end: some View {
        if let label = item.availability.unavailableReason?.badge {
            SelectorUnavailableBadge(label: label)
        } else {
            Checkmark.Label(isChecked: item.isSelected)
        }
    }
}

struct AccountPickerAvatar: View {
    let icon: AccountIconView.ViewData

    var body: some View {
        switch icon {
        case .composite(let fill, .letter(let letter, _)):
            Avatar(.user(.initial(letter, fill: fill)))
        case .composite(let fill, .imageType(let imageType, _)):
            Avatar(.account(imageType, fill: fill))
        case .standalone(let imageType):
            Avatar(.asset(imageType.image))
        }
    }
}

// MARK: - Previews

#Preview {
    let accounts = [
        AccountPickerAccountItem(
            id: "main",
            name: "Main account",
            icon: .composite(backgroundColor: .blue, nameMode: .imageType(Assets.Accounts.family)),
            badge: nil,
            subtitle: "12 tokens •",
            balance: .loaded("$4,496.75"),
            availability: .available,
            isSelected: true
        ),
        AccountPickerAccountItem(
            id: "joint",
            name: "Family",
            icon: .composite(backgroundColor: .orange, nameMode: .letter("F")),
            badge: "Joint",
            subtitle: "3 tokens •",
            balance: .loading(cached: nil),
            availability: .available,
            isSelected: false
        ),
        AccountPickerAccountItem(
            id: "added",
            name: "Savings",
            icon: .composite(backgroundColor: .green, nameMode: .imageType(Assets.Accounts.beach)),
            badge: nil,
            subtitle: "1 token •",
            balance: .loaded("$12.40"),
            availability: .unavailable(SelectorUnavailableReason(badge: nil, title: "Added", message: "Already added")),
            isSelected: false
        ),
    ]

    ScrollView {
        AccountPickerList(
            sections: [
                AccountPickerUserWalletSection(id: "1", header: AccountPickerUserWalletSection.Header(name: "My wallet", thumbnail: nil), accounts: accounts),
                AccountPickerUserWalletSection(id: "2", header: AccountPickerUserWalletSection.Header(name: "My wallet 2", thumbnail: nil), accounts: [accounts[0]]),
            ],
            isBalanceMasked: false,
            onTap: { _ in }
        )
        .padding(16)
    }
}
