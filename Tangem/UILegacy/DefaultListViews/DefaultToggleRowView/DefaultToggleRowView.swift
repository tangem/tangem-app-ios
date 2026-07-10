//
//  DefaultToggleRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct DefaultToggleRowView: View {
    private let viewModel: DefaultToggleRowViewModel
    @State private var isOn: Bool

    init(viewModel: DefaultToggleRowViewModel) {
        self.viewModel = viewModel
        isOn = viewModel.isOn.value
    }

    var body: some View {
        HStack {
            Text(viewModel.title)
                .style(
                    Fonts.Regular.callout,
                    color: viewModel.isDisabled ? Colors.Text.disabled : Colors.Text.primary1
                )

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Colors.Control.checked)
                .disabled(viewModel.isDisabled)
        }
        .padding(.vertical, 8)
        .connect(state: $isOn, to: viewModel.isOn)
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @State var viewModel = DefaultToggleRowViewModel(
        title: "Title",
        isDisabled: false,
        isOn: .constant(false)
    )

    DefaultToggleRowView(viewModel: viewModel)
}
