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
    @State private var isSelected: Bool = false

    init(viewModel: DefaultSelectableRowViewModel) {
        self.viewModel = viewModel
        self.isSelected = viewModel.isSelected
    }

    var body: some View {
        Button {
            withAnimation(nil) {
                isSelected.toggle()
            }
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
                
                SelectedToggle(isSelected: $isSelected)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onChange(of: isSelected, perform: { viewModel.isSelected = $0 })
    }
}

struct SelectedToggle: View {
    @Binding private var isSelected: Bool
    
    init(isSelected: Binding<Bool>) {
        _isSelected = isSelected
    }

    var body: some View {
        Group {
            if isSelected {
                Assets.check.resizable()
            } else {
                // Need to cover empty place if unchecking
                Rectangle()
                    .fill(Color.clear)
            }
        }
        .frame(width: 20, height: 20)
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
