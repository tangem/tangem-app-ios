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
        ZStack {
            Colors.Background.secondary.edgesIgnoringSafeArea(.all)

            GroupedScrollView {
                warningSection

                savingWalletSection

                savingAccessCodesSection
            }
        }
        .alert(item: $viewModel.alert) { $0.alert }
        .navigationBarTitle("app_settings_title", displayMode: .inline)
    }

    @ViewBuilder
    private var warningSection: some View {
        GroupedSection(viewModel.warningViewModel) {
            DefaultWarningRow(viewModel: $0)
        }
    }

    private var savingWalletSection: some View {
        GroupedSection(viewModel.savingWalletViewModel) {
            DefaultToggleRowView(viewModel: $0)
        } footer: {
            DefaultFooterView("app_settings_saved_wallet_footer".localized)
        }
    }

    private var savingAccessCodesSection: some View {
        GroupedSection(viewModel.savingAccessCodesViewModel) {
            DefaultToggleRowView(viewModel: $0)
        } footer: {
            DefaultFooterView("app_settings_saved_access_codes_footer".localized)
        }
    }
}
