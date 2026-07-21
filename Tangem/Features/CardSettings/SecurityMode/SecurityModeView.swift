//
//  SecurityModeView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

struct SecurityModeView: View {
    @ObservedObject var viewModel: SecurityModeViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            Colors.Background.secondary.edgesIgnoringSafeArea(.all)

            GroupedScrollView {
                GroupedSection(viewModel.securityViewModels) {
                    DefaultSelectableRowView(data: $0, selection: $viewModel.currentSecurityOption)
                }
            }
            .interContentPadding(8)

            actionButton
        }
        .alert(item: $viewModel.error) { $0.alert }
        .navigationBarTitle(Text(Localization.cardSettingsSecurityMode), displayMode: .inline)
    }

    private var actionButton: some View {
        MainButton(
            title: Localization.commonSaveChanges,
            icon: .trailing(Assets.tangemIcon),
            isLoading: viewModel.isLoading,
            isDisabled: !viewModel.isActionButtonEnabled,
            action: viewModel.actionButtonDidTap
        )
        .padding(16)
    }
}

#Preview {
    NavigationStack {
        SecurityModeView(viewModel: .init(
            securityOptionChangeInteractor: SecurityOptionChangingMock(),
            coordinator: SecurityModeCoordinator()
        ))
    }
}
