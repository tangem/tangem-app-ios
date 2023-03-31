//
//  SecurityModeView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct SecurityModeView: View {
    @ObservedObject var viewModel: SecurityModeViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            Colors.Background.secondary.edgesIgnoringSafeArea(.all)

            GroupedScrollView {
                SelectableGropedSection(
                    viewModel.securityViewModels,
                    selection: $viewModel.currentSecurityOption
                ) {
                    DefaultSelectableRowView(viewModel: $0)
                }
            }

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

struct SecurityModeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SecurityModeView(viewModel: .init(
                cardModel: PreviewCard.tangemWalletEmpty.cardModel,
                coordinator: SecurityModeCoordinator()
            ))
        }
    }
}
