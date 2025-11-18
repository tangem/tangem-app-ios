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
import TangemAccounts
import TangemLocalization

struct UserSettingsAccountsSectionView: View {
    @ObservedObject var viewModel: UserSettingsAccountsViewModel

    var body: some View {
        ReorderableGroupedSection(
            reorderableModels: $viewModel.accountRows,
            reorderableContent: { model in
                accountContentView(from: model)
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
            sectionFooter: viewModel.archivedAccountButton.map {
                makeSectionFooter(from: $0)
            },
            footer: {
                // We dont have reordering on iOS below 16.0
                if #available(iOS 16.0, *) {
                    Text(Localization.accountReorderDescription)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                }
            }
        )
    }

    private func accountContentView(from model: UserSettingsAccountRowViewData) -> some View {
        Button(action: model.onTap) {
            RowWithLeadingAndTrailingIcons(
                leadingIcon: {
                    AccountIconView(data: model.accountIconViewData)
                },
                content: {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(model.name)
                            .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                        Text(model.description)
                            .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                    }
                },
                trailingIcon: {
                    trailingChevron
                }
            )
        }
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
