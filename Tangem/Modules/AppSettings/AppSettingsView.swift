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

    private var warningSection: some View {
        GroupedSection(viewModel.warningSection) {
            DefaultWarningRow(viewModel: $0)
        }
    }
    
    private var savingWalletSection: some View {
        GroupedSection(viewModel.savingWalletSection) {
            DefaultToggleRowView(viewModel: $0)
        } footer: {
            DefaultFooterView(title: "app_settings_saved_wallet_footer".localized)
        }
        .contentVerticalPadding(4)
    }
    
    private var savingAccessCodesSection: some View {
        GroupedSection(viewModel.savingAccessCodesSection) {
            DefaultToggleRowView(viewModel: $0)
        } footer: {
            DefaultFooterView(title: "app_settings_saved_access_codes_footer".localized)
        }
        .contentVerticalPadding(4)
    }
}
