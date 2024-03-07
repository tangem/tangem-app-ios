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

            GroupedScrollView(spacing: 24) {
                appCurrencySection

                warningSection

                savingWalletSection

                savingAccessCodesSection

                sensitiveTextAvailabilitySection

                themeSettingsSection

                defaultFeeSections
            }
            .interContentPadding(8)
        }
        .alert(item: $viewModel.alert) { $0.alert }
        .navigationBarTitle(Text(Localization.appSettingsTitle), displayMode: .inline)
    }

    @ViewBuilder
    private var appCurrencySection: some View {
        GroupedSection(viewModel.currencySelectionViewModel) {
            DefaultRowView(viewModel: $0)
        }
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
                // Workaround for force rendering the view
                // Will be update in [REDACTED_INFO]
                // Use @Published from directly from the ViewModel
                .id(viewModel.isSavingWallet)
        } footer: {
            DefaultFooterView(Localization.appSettingsSavedWalletFooter)
        }
    }

    private var savingAccessCodesSection: some View {
        GroupedSection(viewModel.savingAccessCodesViewModel) {
            DefaultToggleRowView(viewModel: $0)
                // Workaround for force rendering the view
                // Will be update in [REDACTED_INFO]
                // Use @Published from directly from the ViewModel
                .id(viewModel.isSavingAccessCodes)
        } footer: {
            DefaultFooterView(Localization.appSettingsSavedAccessCodesFooter)
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

    @ViewBuilder
    private var defaultFeeSections: some View {
        GroupedSection(viewModel.defaultFeeViewModel) {
            DefaultToggleRowView(viewModel: $0)
        } footer: {
            DefaultFooterView(Localization.appSettingsDefaultFeeFooter)
        }

        if viewModel.showDefaultFeeOptionSelector {
            SelectableGropedSection(
                viewModel.defaultFeeOptionViewModels,
                selection: $viewModel.defaultFeeOption,
                content: {
                    DefaultSelectableRowView(viewModel: $0)
                }
            )
        }
    }
}
