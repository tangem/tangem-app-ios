//
//  FeatureStateRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct FeatureStateRowView: View {
    private let viewModel: FeatureStateRowViewModel
    @State private var state: FeatureState

    init(viewModel: FeatureStateRowViewModel) {
        self.viewModel = viewModel
        state = viewModel.state.value
    }

    var body: some View {
        content
            .connect(state: $state, to: viewModel.state)
    }

    private var content: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 0) {
                Text(viewModel.feature.name)
                    .style(Fonts.Bold.body, color: Colors.Text.primary1)

                Text("Release version: \(viewModel.releaseVersionInfo)")
                    .style(Fonts.Regular.caption1, color: Colors.Text.secondary)
                    .padding(.top, 4)

                Text("Default state: \(viewModel.defaultState)")
                    .style(Fonts.Regular.caption1, color: Colors.Text.secondary)
                    .padding(.top, 2)
            }

            Picker("", selection: $state) {
                ForEach(FeatureState.allCases) {
                    Text($0.name).tag($0)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
        }
        .padding(.vertical, 12)
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @State var state: FeatureState = .default

    FeatureStateRowView(
        viewModel: FeatureStateRowViewModel(
            feature: .disableFirmwareVersionLimit,
            enabledByDefault: true,
            state: $state.asBindingValue
        )
    )
}
