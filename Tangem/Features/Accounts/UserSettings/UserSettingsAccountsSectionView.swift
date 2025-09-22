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
            afterSeparatorContentModels: [
                viewModel.archivedAccountButton,
            ].compactMap { $0 },
            contentAfterSeparator: { model in
                BaseOneLineRowButton(
                    icon: nil,
                    title: model.text,
                    shouldShowTrailingIcon: false,
                    action: model.action,
                    trailingView: {
                        Assets.chevronRight.image
                            .renderingMode(.template)
                            .foregroundStyle(Colors.Icon.informative)
                    }
                )
            },
            header: {
                accountsSectionHeader
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
                    AccountIconView(backgroundColor: model.iconColor, nameMode: model.iconNameMode)
                        .padding(8)
                        .cornerRadius(10)
                        .imageSize(.init(bothDimensions: 20))
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
                    Assets.chevronRight.image
                        .renderingMode(.template)
                        .foregroundStyle(Colors.Icon.informative)
                }
            )
        }
    }

    private var accountsSectionHeader: some View {
        Text(Localization.commonAccounts)
            .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
    }
}
