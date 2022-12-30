//
//  DefaultSelectableRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct DefaultSelectableRowView: View {
    /// `Binding` required for trigger redrawing the view
    @Binding private var viewModel: DefaultSelectableRowViewModel
    /// `@Binding isSelected` must be here to push changes at the place where this object was created
    @Binding private var isSelected: Bool

    init(viewModel: DefaultSelectableRowViewModel) {
        _viewModel = .constant(viewModel)
        _isSelected = viewModel.$isSelected
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
                    /// Off default behavior with fade animation
                    .animation(nil, value: isSelected)
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
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
