//
//  NewAppSettingsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

struct NewAppSettingsView: View {
    @ObservedObject var viewModel: NewAppSettingsViewModel

    var body: some View {
        ZStack {
            Colors.Background.secondary.edgesIgnoringSafeArea(.all)

            GroupedScrollView(contentType: .lazy(alignment: .center, spacing: 24)) {
                appCurrencySection

                warningSection

                useBiometricAuthenticationSection

                requireAccessCodesSection

                sensitiveTextAvailabilitySection

                themeSettingsSection
            }
            .interContentPadding(8)
        }
        .alert(item: $viewModel.alert) { $0.alert }
        .navigationBarTitle(Text(Localization.appSettingsTitle), displayMode: .inline)
    }

    private var appCurrencySection: some View {
        GroupedSection(viewModel.currencySelectionViewModel) {
            DefaultRowView(viewModel: $0)
        }
    }

    private var warningSection: some View {
        GroupedSection(viewModel.warningViewModel) {
            DefaultWarningRow(viewModel: $0)
        }
    }

    private var useBiometricAuthenticationSection: some View {
        GroupedSection(viewModel.useBiometricAuthenticationViewModel) {
            DefaultToggleRowView(viewModel: $0)
                // Workaround for force rendering the view
                // Will be update in [REDACTED_INFO]
                // Use @Published from directly from the ViewModel
                .id(viewModel.useBiometricAuthentication)
        } footer: {
            DefaultFooterView(Localization.appSettingsBiometricsFooter(viewModel.biometricsTitle))
        }
    }

    private var requireAccessCodesSection: some View {
        GroupedSection(viewModel.requireAccessCodesViewModel) {
            DefaultToggleRowView(viewModel: $0)
                // Workaround for force rendering the view
                // Will be update in [REDACTED_INFO]
                // Use @Published from directly from the ViewModel
                .id(viewModel.requireAccessCodes)
        } footer: {
            DefaultFooterView(Localization.appSettingsRequireAccessCodeFooter)
        }
    }

    private var sensitiveTextAvailabilitySection: some View {
        GroupedSection(viewModel.sensitiveTextAvailabilityViewModel) {
            DefaultToggleRowView(viewModel: $0)
        } footer: {
            DefaultFooterView(Localization.detailsRowDescriptionFlipToHide)
        }
    }

    private var themeSettingsSection: some View {
        GroupedSection(viewModel.themeSettingsViewModel) {
            DefaultRowView(viewModel: $0)
        }
    }
}
