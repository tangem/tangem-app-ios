//
//  UserWalletSettingsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI
import TangemAccounts

struct UserWalletSettingsView: View {
    @ObservedObject private var viewModel: UserWalletSettingsViewModel

    init(viewModel: UserWalletSettingsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        GroupedScrollView(alignment: .leading, spacing: 24) {
            nameSection

            mobileUpgradeSection

            if viewModel.accountsViewModel.accountRows.isNotEmpty {
                accountsSection
            }

            mobileAccessCodeSection

            backupSection

            commonSection

            nftSection

            pushNotifySection

            forgetSection
        }
        .interContentPadding(8)
        .background(Colors.Background.secondary.ignoresSafeArea())
        .navigationTitle(Localization.walletSettingsTitle)
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $viewModel.alert) { $0.alert }
        .actionSheet(item: $viewModel.actionSheet) { $0.sheet }
        .scrollDismissesKeyboardCompat(.interactively)
        .onAppear(perform: viewModel.onAppear)
    }

    private var nameSection: some View {
        DefaultTextFieldRowView(
            title: Localization.settingsWalletNameTitle,
            text: .constant(viewModel.name),
            isReadonly: true
        )
        .defaultRoundedBackground()
        .onTapGesture(perform: viewModel.onTapNameField)
    }

    private var mobileUpgradeSection: some View {
        viewModel.mobileUpgradeNotificationInput.map {
            NotificationView(input: $0)
        }
    }

    @ViewBuilder
    private var accountsSection: some View {
        ReorderableGroupedSection(
            reorderableModels: $viewModel.accountsViewModel.accountRows,
            reorderableContent: { model in
                accountContentView(from: model)
            },
            staticModels: [
                viewModel.accountsViewModel.addNewAccountButton,
            ].compactMap { $0 },
            staticContent: { viewData in
                AddListItemButton(viewData: viewData)
            },
            afterSeparatorContentModels: [
                viewModel.accountsViewModel.archivedAccountButton,
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
                    AccountIconView(backgroundColor: model.iconColor, nameMode: model.icon)
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

    private var mobileAccessCodeSection: some View {
        GroupedSection(
            viewModel.mobileAccessCodeViewModel,
            content: {
                DefaultRowView(viewModel: $0).appearance(.accentButton)
            },
            footer: {
                DefaultFooterView(Localization.walletSettingsAccessCodeDescription)
            }
        )
    }

    private var backupSection: some View {
        GroupedSection(viewModel.backupViewModel) {
            DefaultRowView(viewModel: $0)
        }
    }

    private var nftSection: some View {
        GroupedSection(viewModel.nftViewModel) {
            DefaultToggleRowView(viewModel: $0)
        }
    }

    private var commonSection: some View {
        GroupedSection(viewModel.commonSectionModels) {
            DefaultRowView(viewModel: $0)
        }
    }

    @ViewBuilder
    private var pushNotifySection: some View {
        if let pushNotificationsViewModel = viewModel.pushNotificationsViewModel {
            TransactionNotificationsRowToggleView(viewModel: pushNotificationsViewModel)
        }
    }

    private var forgetSection: some View {
        GroupedSection(viewModel.forgetViewModel) {
            DefaultRowView(viewModel: $0)
                .appearance(.destructiveButton)
        } footer: {
            DefaultFooterView(Localization.settingsForgetWalletFooter)
        }
    }
}

struct UserWalletSettingsView_Preview: PreviewProvider {
    static let viewModel = UserWalletSettingsViewModel(
        userWalletModel: UserWalletModelMock(),
        coordinator: UserWalletSettingsCoordinator()
    )

    static var previews: some View {
        UserWalletSettingsView(viewModel: viewModel)
    }
}
