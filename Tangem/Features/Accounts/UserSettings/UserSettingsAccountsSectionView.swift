//
//  UserSettingsAccountsSectionView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct UserSettingsAccountsSectionView: View {
    @ObservedObject var viewModel: UserSettingsAccountsViewModel

    var body: some View {
        ReorderableGroupedSection(
            reorderableModels: $viewModel.accountRows,
            reorderableContent: { accountRow in
                AccountRowButtonView(viewModel: accountRow.viewModel) {
                    trailingChevron
                }
            },
            staticModels: [
                viewModel.addNewAccountButton,
            ].compactMap { $0 },
            staticContent: { viewData in
                AddListItemButton(viewData: viewData)
            },
            sectionHeader: {
                accountsSectionHeader
            },
            sectionFooter: viewModel.archivedAccountsButton.map {
                makeSectionFooter(from: $0)
            },
            footer: {
                // there is no need to show "reorder" text if there are less than 2 accounts
                if viewModel.moreThatOneActiveAccount {
                    Text(Localization.accountReorderDescription)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                }
            }
        )
    }

    private var accountsSectionHeader: some View {
        Text(Localization.commonAccounts)
            .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
    }

    private func makeSectionFooter(from buttonModel: UserSettingsAccountsViewModel.ArchivedAccountsButtonViewData) -> some View {
        BaseOneLineRowButton(
            icon: nil,
            title: buttonModel.text,
            shouldShowTrailingIcon: false,
            action: buttonModel.action,
            trailingView: {
                trailingChevron
            }
        )
    }

    private var trailingChevron: some View {
        Assets.chevronRight.image
            .renderingMode(.template)
            .foregroundStyle(Colors.Icon.informative)
    }
}
