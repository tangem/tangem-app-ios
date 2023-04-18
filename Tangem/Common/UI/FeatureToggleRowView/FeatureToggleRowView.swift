//
//  FeatureToggleRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct FeatureToggleRowView: View {
    let viewModel: FeatureToggleRowViewModel

    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.toggle.name)
                    .style(Fonts.Bold.body, color: Colors.Text.primary1)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Release version: \(viewModel.releaseVersionInfo)")
                        .style(Fonts.Regular.caption1, color: Colors.Text.secondary)

                    Text("State by default: \(viewModel.stateByDefault)")
                        .style(Fonts.Regular.caption1, color: Colors.Text.secondary)
                }
            }

            Picker("", selection: viewModel.state) {
                ForEach(FeatureState.allCases) {
                    Text($0.rawValue).tag($0)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
        }
        .padding(.vertical, 12)
    }
}

struct FeatureToggleRowView_Preview: PreviewProvider {
    struct ContentView: View {
        @State private var state: FeatureState = .default
        var body: some View {
            FeatureToggleRowView(
                viewModel: FeatureToggleRowViewModel(
                    toggle: .exchange,
                    isEnabledByDefault: true,
                    state: $state
                )
            )
        }
    }

    static var previews: some View {
        ContentView()
    }
}
