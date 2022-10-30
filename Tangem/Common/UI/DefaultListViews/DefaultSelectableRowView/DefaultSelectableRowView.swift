//
//  DefaultSelectableRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct DefaultSelectableRowView: View {
    private var viewModel: DefaultSelectableRowViewModel

    init(viewModel: DefaultSelectableRowViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Button {
            viewModel.isSelected.toggle()
        } label: {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.title)
                        .style(Fonts.Regular.body, color: Colors.Text.primary1)

                    if let subtitle = viewModel.subtitle {
                        Text(subtitle)
                            .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    }
                }

                Spacer(minLength: 12)

                SelectedToggle(isSelected: viewModel.$isSelected)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DefaultSelectableRowViewPreview: PreviewProvider {
    static var isSelected: Bool = true
    static let viewModel = DefaultSelectableRowViewModel(
        title: "Long Tap",
        subtitle: "This mechanism protects against proximity attacks on a card. It will enforce a delay.",
        isSelected: .init(get: { isSelected },
                          set: { isSelected = $0 })
    )

    static var previews: some View {
        DefaultSelectableRowView(viewModel: viewModel)
    }
}
