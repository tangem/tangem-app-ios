//
//  UserWalletSelectorList.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation
import TangemUI
import TangemUIUtils

public struct UserWalletSelectorList: View {
    private let items: [UserWalletSelectorItem]
    private let isBalanceMasked: Bool
    private let onTap: (UserWalletSelectorItem) -> Void

    public init(items: [UserWalletSelectorItem], isBalanceMasked: Bool, onTap: @escaping (UserWalletSelectorItem) -> Void) {
        self.items = items
        self.isBalanceMasked = isBalanceMasked
        self.onTap = onTap
    }

    public var body: some View {
        SelectorCard {
            ForEach(items) { item in
                UserWalletSelectorRow(item: item, isBalanceMasked: isBalanceMasked) {
                    onTap(item)
                }
            }
        }
    }
}

struct UserWalletSelectorRow: View {
    let item: UserWalletSelectorItem
    let isBalanceMasked: Bool
    let onTap: () -> Void

    var body: some View {
        Row(title: item.name)
            .start { WalletIconView(content: item.icon, width: 40) }
            .subtitleAccessory { subtitle }
            .end { badge }
            .onTap(action: onTap)
            .disabled(isLocked)
    }

    private var isLocked: Bool {
        item.availability.isLocked
    }

    @ViewBuilder
    private var subtitle: some View {
        if isLocked {
            SelectorLockedSubtitle()
        } else {
            SelectorBalanceText(balance: item.balance, isMasked: isBalanceMasked)
        }
    }

    @ViewBuilder
    private var badge: some View {
        if let label = item.availability.unavailableReason?.badge {
            SelectorUnavailableBadge(label: label)
        }
    }
}

// MARK: - Previews

#Preview {
    let unavailableReason = SelectorUnavailableReason(badge: "Full", title: "Can’t add new account", message: "Archive one to add a new one.")

    UserWalletSelectorList(
        items: [
            UserWalletSelectorItem(id: UserWalletId(value: Data([1])), name: "My wallet", icon: nil, balance: .loaded("$4,496.75"), availability: .unavailable(unavailableReason)),
            UserWalletSelectorItem(id: UserWalletId(value: Data([2])), name: "My wallet 2", icon: nil, balance: .loading(cached: "$12,399.12"), availability: .available),
            UserWalletSelectorItem(id: UserWalletId(value: Data([3])), name: "My wallet 3", icon: nil, balance: .loading(cached: nil), availability: .available),
            UserWalletSelectorItem(id: UserWalletId(value: Data([4])), name: "My wallet 4", icon: nil, balance: .loaded("$901.44"), availability: .locked),
        ],
        isBalanceMasked: false,
        onTap: { _ in }
    )
    .padding(16)
}
