//
//  DefaultPickerRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct DefaultPickerRowView: View {
    private let viewModel: DefaultPickerRowViewModel
    @State private var selection: String

    init(viewModel: DefaultPickerRowViewModel) {
        self.viewModel = viewModel
        selection = viewModel.selection.value
    }

    var body: some View {
        content
            .connect(state: $selection, to: viewModel.selection)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.pickerStyle {
        case .segmented:
            VStack(alignment: .leading) {
                Text(viewModel.title)
                    .style(Fonts.Bold.callout, color: Colors.Text.primary1)

                segmentedPicker
            }
            .padding(.vertical, 14)
        case .menu:
            menuPicker
        }
    }

    private var segmentedPicker: some View {
        Picker("", selection: $selection) {
            ForEach(viewModel.options.indices, id: \.self) { index in
                Text(viewModel.displayOptions[index]).tag(viewModel.options[index])
            }
        }
        .labelsHidden()
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private var menuPicker: some View {
        let actions = viewModel.options.indices.map { index in
            PickerModelAction(id: viewModel.options[index], title: viewModel.displayOptions[index])
        }

        if let firstAction = actions.first {
            let selectedAction = Binding<PickerModelAction>(
                get: {
                    actions.first(where: { $0.id == selection }) ?? firstAction
                },
                set: { action in
                    selection = action.id
                }
            )

            DefaultMenuRowView(
                viewModel: .init(title: viewModel.title, actions: actions),
                selection: selectedAction,
                titleFont: Fonts.Bold.callout
            )
        } else {
            EmptyView()
        }
    }
}

private struct PickerModelAction: DefaultMenuRowViewModelAction {
    let id: String
    let title: String
}
