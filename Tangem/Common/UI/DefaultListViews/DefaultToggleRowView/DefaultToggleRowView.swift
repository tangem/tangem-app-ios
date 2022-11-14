//
//  DefaultToggleRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct DefaultToggleRowView: View {
    private let viewModel: DefaultToggleRowViewModel

    init(viewModel: DefaultToggleRowViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        HStack {
            Text(viewModel.title)
                .style(Fonts.Regular.body,
                       color: viewModel.isDisabled ? Colors.Text.disabled : Colors.Text.primary1)

            Spacer()

            Toggle("", isOn: viewModel.$isOn)
                .labelsHidden()
                .toggleStyleCompat(Colors.Control.checked)
                .disabled(viewModel.isDisabled)
        }
        .padding(.vertical, 8)
    }
}

struct DefaultToggleRowViewPreview: PreviewProvider {
    static let viewModel = DefaultToggleRowViewModel(
        title: "Title",
        isOn: .constant(true)
    )

    static var previews: some View {
        DefaultToggleRowView(viewModel: viewModel)
    }
}
