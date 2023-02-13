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

    /// `@Binding isSelected` must be here to push changes at the place where this object was created
    @Binding private var isSelected: Bool

    init(viewModel: DefaultSelectableRowViewModel) {
        self.viewModel = viewModel
        _isSelected = viewModel.isSelected()
    }

    var body: some View {
        Button(action: { isSelected.toggle() }) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.title)
                        .style(Fonts.Regular.body, color: Colors.Text.primary1)
                        .multilineTextAlignment(.leading)

                    if let subtitle = viewModel.subtitle {
                        Text(subtitle)
                            .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer(minLength: 12)

                CheckIconView(isSelected: $isSelected)
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
    }
}

struct DefaultSelectableRowViewPreview: PreviewProvider {
    struct ContainerView: View {
        @State private var isSelected: Bool = false

        var body: some View {
            DefaultSelectableRowView(
                viewModel: DefaultSelectableRowViewModel(
                    title: "Long Tap",
                    subtitle: "This mechanism protects against proximity attacks on a card. It will enforce a delay.",
                    isSelected: { $isSelected }
                )
            )
        }
    }

    static var previews: some View {
        ContainerView().padding()
    }
}
