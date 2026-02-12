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
        GroupedScrollView(contentType: .lazy(alignment: .leading, spacing: 24)) {
            walletSection

            accountsSection

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
        .scrollDismissesKeyboard(.interactively)
        .onFirstAppear(perform: viewModel.onFirstAppear)
        .onAppear(perform: viewModel.onAppear)
    }

    @ViewBuilder
    private var walletSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            walletRenameSubsection
            mobileUpgradeSubsection
        }
        .defaultRoundedBackground()
    }

    @ViewBuilder
    private var walletIcon: some View {
        if let walletImage = viewModel.walletImage {
            walletImage
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .cornerRadius(10)
        }
    }

    @ViewBuilder
    private var walletRenameSubsection: some View {
        if FeatureProvider.isAvailable(.accounts) {
            Button(action: viewModel.onTapNameField) {
                InfoRowWithAction(
                    icon: { walletIcon },
                    title: Localization.settingsWalletNameTitle,
                    value: viewModel.name,
                    actionTitle: Localization.commonRename,
                    onAction: viewModel.onTapNameField
                )
            }
        } else {
            DefaultTextFieldRowView(
                title: Localization.settingsWalletNameTitle,
                text: .constant(viewModel.name),
                isReadonly: true
            )
            .onTapGesture(perform: viewModel.onTapNameField)
        }
    }

    @ViewBuilder
    private var mobileUpgradeSubsection: some View {
        if viewModel.isMobileUpgradeAvailable {
            VStack(alignment: .leading, spacing: 12) {
                Separator(height: .exact(0.5), color: Colors.Stroke.primary)

                DefaultRowView(viewModel: DefaultRowViewModel(
                    title: Localization.detailsMobileWalletUpgradeActionTitle,
                    action: viewModel.mobileUpgradeTap
                ))
                .appearance(.init(
                    isChevronVisible: false,
                    textColor: Colors.Text.accent,
                    hasVerticalPadding: false
                ))
            }
        }
    }

    // [REDACTED_TODO_COMMENT]
    private var mobileUpgradeSection: some View {
        viewModel.mobileUpgradeNotificationInput.map {
            NotificationView(input: $0)
        }
    }

    @ViewBuilder
    private var accountsSection: some View {
        viewModel.accountsViewModel.map { viewModel in
            UserSettingsAccountsSectionView(viewModel: viewModel)
        }
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
                .confirmationDialog(viewModel: $viewModel.forgetWalletConfirmationDialog)
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
