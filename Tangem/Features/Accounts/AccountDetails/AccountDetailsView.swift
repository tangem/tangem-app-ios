//
//  AccountDetailsView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAccounts
import TangemLocalization
import TangemAssets
import TangemAccessibilityIdentifiers

struct AccountDetailsView: View {
    @ObservedObject var viewModel: AccountDetailsViewModel

    var body: some View {
        GroupedScrollView(contentType: .plain(spacing: 20)) {
            accountSection

            managementSection

            archiveAccountSection
        }
        .horizontalPadding(0)
        .alert(item: $viewModel.alert) { $0.alert }
        .onFirstAppear(perform: viewModel.onFirstAppear)
    }

    @ViewBuilder
    private var accountSection: some View {
        if viewModel.canBeEdited {
            SwiftUI.Button(action: viewModel.openEditAccount) {
                accountSectionContent
            }
        } else {
            accountSectionContent
        }
    }

    private var accountSectionContent: some View {
        RowWithLeadingAndTrailingIcons(
            leadingIcon: {
                AccountIconView(data: viewModel.accountIconViewData)
            },
            content: {
                VStack(alignment: .leading, spacing: 2.0) {
                    Text(Localization.accountFormName)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

                    Text(viewModel.accountName)
                        .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                        .accessibilityIdentifier(AccountsAccessibilityIdentifiers.accountDetailsAccountName)
                }
            },
            trailingIcon: {
                if viewModel.canBeEdited {
                    CapsuleButton(
                        title: Localization.commonEdit,
                        action: viewModel.openEditAccount
                    )
                    .accessibilityIdentifier(AccountsAccessibilityIdentifiers.accountDetailsEditButton)
                }
            }
        )
        .defaultRoundedBackground(with: Colors.Background.action)
    }

    private var managementSection: some View {
        GroupedSection(viewModel.managementRowViewModels) {
            DefaultRowView(viewModel: $0)
        } footer: {
            if let supportedNetworksHint = viewModel.supportedNetworksHint {
                Text(supportedNetworksHint)
                    .environment(\.openURL, OpenURLAction { _ in
                        viewModel.openSupportedNetworks()
                        return .handled
                    })
            }
        }
        .backgroundColor(Colors.Background.action)
    }

    private var archiveAccountSection: some View {
        GroupedSection(viewModel.archiveRowViewModel) {
            DefaultRowView(viewModel: $0)
                .appearance(viewModel.isArchivingInProgress ? .disabledDestructiveButton : .destructiveButton)
        } footer: {
            DefaultFooterView(Localization.accountDetailsArchiveDescription)
        }
        .backgroundColor(Colors.Background.action)
        .animation(.default, value: viewModel.archivingState)
        .confirmationDialog(
            Localization.accountDetailsArchiveDescription,
            isPresented: $viewModel.archiveAccountDialogPresented,
            titleVisibility: .visible
        ) {
            SwiftUI.Button(Localization.accountDetailsArchive, role: .destructive) {
                viewModel.archiveAccount()
            }
        }
        .onChange(of: viewModel.archiveAccountDialogPresented) { isPresented in
            if !isPresented {
                viewModel.handleDialogDismissed()
            }
        }
    }
}
