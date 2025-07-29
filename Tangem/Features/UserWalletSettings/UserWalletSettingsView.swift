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
import TangemAccessibilityIdentifiers

struct UserWalletSettingsView: View {
    @ObservedObject private var viewModel: UserWalletSettingsViewModel

    init(viewModel: UserWalletSettingsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        GroupedScrollView(alignment: .leading, spacing: 24) {
            nameSection

            accessCodeSection

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

    private var accessCodeSection: some View {
        GroupedSection(
            viewModel.hotAccessCodeViewModel,
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
        GroupedSection(viewModel.commonSectionModels) { viewModel in
            DefaultRowView(viewModel: viewModel)
                .accessibilityIdentifier(viewModel.title == Localization.detailsReferralTitle ? CardSettingsAccessibilityIdentifiers.referralProgramButton : "")
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
