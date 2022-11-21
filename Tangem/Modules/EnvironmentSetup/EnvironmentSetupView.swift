//
//  EnvironmentSetupView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct EnvironmentSetupView: View {
    @ObservedObject private var viewModel: EnvironmentSetupViewModel

    init(viewModel: EnvironmentSetupViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            Colors.Background.secondary.edgesIgnoringSafeArea(.all)

            GroupedScrollView {
                GroupedSection(viewModel.appSettingsTogglesViewModels) {
                    DefaultToggleRowView(viewModel: $0)
                } header: {
                    DefaultHeaderView("App settings")
                }

                GroupedSection(viewModel.togglesViewModels) { viewModel in
                    DefaultToggleRowView(viewModel: viewModel)
                } header: {
                    DefaultHeaderView("Feature toggles")
                }
            }
        }
        .navigationBarTitle(Text("Environment setup"))
        .navigationBarItems(trailing: exitButton)
        .alert(item: $viewModel.alert) { $0.alert }
    }

    private var exitButton: some View {
        Button("Exit", action: viewModel.showExitAlert)
            .animation(nil)
    }
}

struct EnvironmentSetupView_Preview: PreviewProvider {
    static let viewModel = EnvironmentSetupViewModel()

    static var previews: some View {
        NavigationView {
            EnvironmentSetupView(viewModel: viewModel)
        }
    }
}
