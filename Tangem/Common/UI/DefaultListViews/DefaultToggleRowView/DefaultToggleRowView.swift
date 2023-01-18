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
                .style(
                    Fonts.Regular.body,
                    color: viewModel.isDisabled ? Colors.Text.disabled : Colors.Text.primary1
                )

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
    static var isSelected: Bool = true
    static let viewModel = DefaultToggleRowViewModel(
        title: "Title",
        isDisabled: false,
        isOn: .init(
            get: { isSelected },
            set: { isSelected = $0 }
        )
    )

    static var previews: some View {
        DefaultToggleRowView(viewModel: viewModel)
    }
}
