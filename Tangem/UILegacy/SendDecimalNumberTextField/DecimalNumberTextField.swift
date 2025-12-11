//
//  DecimalNumberTextField.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemAssets
import TangemUIUtils

struct DecimalNumberTextField: View {
    @ObservedObject private var viewModel: DecimalNumberTextFieldViewModel

    // Setupable properties
    private var placeholder: String = "0"
    private var appearance: Appearance = .init()

    init(viewModel: DecimalNumberTextFieldViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack(alignment: .leading) {
            // A dummy invisible view that controls the layout (i.e. limits the max width) of `DecimalNumberTextField`.
            //
            // For unknown reasons, sometimes the calculated width of this view is not enough and causes `textField`
            // to truncate its text. Using `TextField` instead of `Text` doesn't help; the issue persists.
            // To mitigate this, we add additional 1pt horizontal paddings that prevents the text from being truncated.
            Text(viewModel.textFieldTextBinding.value.isEmpty ? placeholder : viewModel.textFieldTextBinding.value)
                .font(appearance.font)
                .padding(.horizontal, 1.0)
                .hidden(true)
                .layoutPriority(1)

            textField
        }
        .lineLimit(1)
    }

    private var textField: some View {
        TextField(text: viewModel.textFieldTextBinding.asBinding, prompt: prompt, label: {})
            .multilineTextAlignment(.center) // Aligns `textField` text; required due to additional horizontal paddings above
            .style(appearance.font, color: appearance.textColor)
            .tint(appearance.textColor)
            .labelsHidden()
            .keyboardType(.decimalPad)
    }

    private var prompt: Text {
        Text(placeholder)
            // We can't use .style(font:, color:) here because
            // We should have the `Text` type
            .font(appearance.font)
            .foregroundColor(appearance.placeholderColor)
    }
}

// MARK: - Setupable

extension DecimalNumberTextField: Setupable {
    func placeholder(_ placeholder: String) -> Self {
        map { $0.placeholder = placeholder }
    }

    func appearance(_ appearance: Appearance) -> Self {
        map { $0.appearance = appearance }
    }
}

struct DecimalNumberTextField_Previews: PreviewProvider {
    static var previews: some View {
        DecimalNumberTextField(viewModel: .init(maximumFractionDigits: 8))
    }
}

// MARK: - Appearance

extension DecimalNumberTextField {
    struct Appearance {
        let font: Font
        let textColor: Color
        let placeholderColor: Color

        init(
            font: Font = Fonts.Regular.title1,
            textColor: Color = Colors.Text.primary1,
            placeholderColor: Color = Colors.Text.disabled
        ) {
            self.font = font
            self.textColor = textColor
            self.placeholderColor = placeholderColor
        }
    }
}
