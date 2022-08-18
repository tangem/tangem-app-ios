//
//  TextInputField.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import SwiftUI

struct TextInputField<SupplementView: View>: View {

    let placeholder: String
    let text: Binding<String>
    let keyboardType: UIKeyboardType
    let clearButtonMode: UITextField.ViewMode
    let suplementView: SupplementView
    let message: String?
    let isErrorMessage: Bool

    init(placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType = .default, clearButtonMode: UITextField.ViewMode = .never, @ViewBuilder suplementView: () -> SupplementView, message: String?, isErrorMessage: Bool) {
        self.placeholder = placeholder
        self.text = text
        self.keyboardType = keyboardType
        self.clearButtonMode = clearButtonMode
        self.suplementView = suplementView()
        self.message = message
        self.isErrorMessage = isErrorMessage
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 0.0) {
                    Text(text.wrappedValue.isEmpty ? " " : placeholder)
                        .font(Font.system(size: 13.0, weight: .medium, design: .default))
                        .foregroundColor(Color.tangemGrayDark)
                    CustomTextField(text: text,
                                    isResponder:  Binding.constant(nil),
                                    actionButtonTapped: Binding.constant(true),
                                    handleKeyboard: true,
                                    keyboard: keyboardType,
                                    clearButtonMode: clearButtonMode,
                                    textColor: UIColor.tangemGrayDark6,
                                    font: UIFont.systemFont(ofSize: 16.0, weight: .regular),
                                    placeholder: placeholder)
                }
                Spacer()
                suplementView
            }
            Color.tangemGrayLight5
                .frame(width: nil, height: 1.0, alignment: .center)
                .padding(.top, 8.0)
                .padding(.bottom, 4.0)

            HStack {
                Text(message ?? " ")
                    .font(Font.system(size: 13.0, weight: .medium, design: .default))
                    .foregroundColor(
                        isErrorMessage ? Color.red : Color.tangemGrayDark
                    )
                Spacer()
            }
        }
    }
}

extension TextInputField where SupplementView == EmptyView {
    init(placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType = .default, clearButtonMode: UITextField.ViewMode, message: String?, isErrorMessage: Bool) {
        self.placeholder = placeholder
        self.text = text
        self.keyboardType = keyboardType
        self.clearButtonMode = clearButtonMode
        self.suplementView = EmptyView()
        self.message = message
        self.isErrorMessage = isErrorMessage
    }
}

struct TextInputField_Previews: PreviewProvider {
    @State static var text = ""
    static var previews: some View {
        TextInputField(placeholder: "Address",
                       text: $text,
                       suplementView: {},
                       message: nil,
                       isErrorMessage: false)
    }
}
