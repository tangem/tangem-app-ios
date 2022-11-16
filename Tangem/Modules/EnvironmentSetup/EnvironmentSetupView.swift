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
        List {
            Section {
                DefaultToggleRowView(title: "isTestnet", isOn: $viewModel.isTestnet)
            } header: {
                Text("App settings")
            }

            Section {
                ForEach(viewModel.toggles) { toggle in
                    DefaultToggleRowView(title: toggle.toggle.name, isOn: toggle.isActive)

                    if viewModel.toggles.last != toggle {
                        Separator()
                    }
                }
            } header: {
                Text("Feature toggles")
            }
        }
        .groupedListStyleCompatibility(background: Colors.Background.secondary)
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
