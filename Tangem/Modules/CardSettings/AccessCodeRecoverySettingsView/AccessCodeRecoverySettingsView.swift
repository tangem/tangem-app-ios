//
//  AccessCodeRecoverySettingsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct AccessCodeRecoverySettingsView: View {
    @ObservedObject var viewModel: AccessCodeRecoverySettingsViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            GroupedScrollView {
                SelectableGropedSection(
                    viewModel.viewModels,
                    selection: $viewModel.accessCodeRecoveryEnabled
                ) {
                    DefaultSelectableRowView(viewModel: $0)
                }
            }
            .disabled(viewModel.isLoading)

            saveChangesButton
        }
        .alert(item: $viewModel.errorAlert, content: { $0.alert })
        .navigationBarTitle(Text(Localization.cardSettingsAccessCodeRecoveryTitle), displayMode: .inline)
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
    }

    @ViewBuilder
    private var saveChangesButton: some View {
        MainButton(
            title: Localization.commonSaveChanges,
            icon: .trailing(Assets.tangemIcon),
            isLoading: viewModel.isLoading,
            isDisabled: viewModel.actionButtonDisabled,
            action: viewModel.actionButtonDidTap
        )
        .padding(16)
    }
}

struct AccessCodeRecoverySettingsView_Previews: PreviewProvider {
    private static let viewModel = AccessCodeRecoverySettingsViewModel(settingsProvider: AccessCodeRecoverySettingsProviderMock())
    static var previews: some View {
        AccessCodeRecoverySettingsView(viewModel: viewModel)
    }
}
