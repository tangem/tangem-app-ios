//
//  AppSettingsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct AppSettingsView: View {
    @ObservedObject private var viewModel: AppSettingsViewModel

    init(viewModel: AppSettingsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        List {
            if !viewModel.isBiometryAvailable {
                warningSection
            }

            savingWalletSection

            savingAccessCodesSection
        }
        .groupedListStyleCompatibility(background: Colors.Background.secondary)
        .alert(item: $viewModel.alert) { $0.alert }
        .navigationBarTitle("app_settings_title", displayMode: .inline)
    }

    private var warningSection: some View {
        Section(content: {
            DefaultWarningRow(
                icon: Assets.attention,
                title: "app_settings_warning_title".localized,
                subtitle: "app_settings_warning_subtitle".localized,
                action: {
                    viewModel.openSettings()
                }
            )
        })
    }

    private var savingWalletSection: some View {
        Section(content: {
            DefaultToggleRowView(
                title: "app_settings_saved_wallet".localized,
                isEnabled: viewModel.isBiometryAvailable,
                isOn: $viewModel.isSavingWallet
            )
        }, footer: {
            DefaultFooterView(title: "app_settings_saved_wallet_footer".localized)
        })
    }

    private var savingAccessCodesSection: some View {
        Section(content: {
            DefaultToggleRowView(
                title: "app_settings_saved_access_codes".localized,
                isEnabled: viewModel.isBiometryAvailable,
                isOn: $viewModel.isSavingAccessCodes
            )
        }, footer: {
            DefaultFooterView(title: "app_settings_saved_access_codes_footer".localized)
        })
    }
}
