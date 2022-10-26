//
//  SetupEnvironmentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct SetupEnvironmentView: View {
    @ObservedObject private var viewModel: SetupEnvironmentViewModel

    init(viewModel: SetupEnvironmentViewModel) {
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
        .groupedListStyleCompatibility()
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
        .navigationBarTitle(Text("Environment setup"))
        .navigationBarItems(trailing: exitButton)
    }
    
    private var exitButton: some View {
        Button("Turn off", action: viewModel.turnOff)
    }
}

struct SetupEnvironmentView_Preview: PreviewProvider {
    static let viewModel = SetupEnvironmentViewModel()

    static var previews: some View {
        NavigationView {
            SetupEnvironmentView(viewModel: viewModel)
        }
    }
}
