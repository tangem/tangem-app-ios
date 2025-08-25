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
        VStack(alignment: .leading) {
            Text(viewModel.title)
                .style(Fonts.Bold.callout, color: Colors.Text.primary1)

            Picker("", selection: $selection) {
                ForEach(viewModel.options.indices, id: \.self) { index in
                    Text(viewModel.displayOptions[index]).tag(viewModel.options[index])
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
        }
        .padding(.vertical, 14)
        .connect(state: $selection, to: viewModel.selection)
    }
}
