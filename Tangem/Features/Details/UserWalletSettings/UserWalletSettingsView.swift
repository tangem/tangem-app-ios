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

            mobileUpgradeSection

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
        .confirmationDialog(viewModel: $viewModel.confirmationDialog)
        .scrollDismissesKeyboard(.interactively)
        .onFirstAppear(perform: viewModel.onFirstAppear)
        .onAppear(perform: viewModel.onAppear)
    }

    @ViewBuilder
    private var walletSection: some View {
        if FeatureProvider.isAvailable(.accounts) {
            InfoRowWithAction(
                icon: {
                    if let walletImage = viewModel.walletImage {
                        walletImage
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .cornerRadius(10)
                    }
                },
                title: Localization.settingsWalletNameTitle,
                value: viewModel.name,
                actionTitle: Localization.commonRename,
                onAction: viewModel.onTapNameField
            )
            .defaultRoundedBackground()
        } else {
            DefaultTextFieldRowView(
                title: Localization.settingsWalletNameTitle,
                text: .constant(viewModel.name),
                isReadonly: true
            )
            .defaultRoundedBackground()
            .onTapGesture(perform: viewModel.onTapNameField)
        }
    }

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
