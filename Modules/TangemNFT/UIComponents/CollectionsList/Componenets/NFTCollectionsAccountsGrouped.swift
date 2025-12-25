//
//  NFTCollectionsAccountsGrouped.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAccounts
import TangemAssets

struct NFTCollectionsAccountsGrouped: View {
    let accountWithCollectionViewModels: AccountWithCollectionViewModels

    var body: some View {
        GroupedSection(
            accountWithCollectionViewModels.collectionsViewModels,
            content: {
                NFTCollectionDisclosureGroupView(viewModel: $0)
                    .id($0.id)
            },
            header: {
                HStack(spacing: 6) {
                    AccountIconView(data: accountWithCollectionViewModels.accountData.iconData)
                        .settings(.smallSized)

                    Text(accountWithCollectionViewModels.accountData.name)
                        .style(Fonts.Bold.footnote, color: Colors.Text.primary1)
                }
                .padding(.top, 14)
            }
        )
    }
}

#if DEBUG
#Preview {
    ZStack {
        Color.gray

        NFTCollectionsAccountsGrouped(
            accountWithCollectionViewModels: AccountWithCollectionViewModels(
                accountData: AccountWithCollectionViewModels.AccountData(
                    id: "ID",
                    name: "Portfolio",
                    iconData: AccountIconView.ViewData(
                        backgroundColor: .red,
                        nameMode: .letter("P")
                    )
                ),
                collectionsViewModels: [
                    .mock(name: "Collection 1"),
                    .mock(name: "Collection 2"),
                    .mock(name: "Collection 3"),
                ]
            )
        )
    }
}
#endif
