//
//  CustomPasswordTextField.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

struct CustomPasswordTextField: View {
    let placeholder: String
    let color: Color
    var backgroundColor: Color = Colors.Field.primary

    var password: Binding<String>
    var shouldBecomeFirstResponder: Bool = true
    var accessibilityIdentifier: String? = nil

    var onEditingChanged: (Bool) -> Void = { _ in }
    var onCommit: () -> Void = {}

    var body: some View {
        FocusableTextField(
            shouldBecomeFirstResponder: shouldBecomeFirstResponder,
            placeholder: placeholder,
            text: password,
            accessibilityIdentifier: accessibilityIdentifier,
            onEditingChanged: onEditingChanged,
            onCommit: onCommit
        )
        .frame(height: 48)
        .transition(.opacity)
        .foregroundColor(color)
        .padding(.leading, 16)
        .background(backgroundColor)
        .cornerRadius(10)
    }
}

private extension CustomPasswordTextField {
    enum Field: Hashable {
        case secure
    }

    struct FocusableTextField: View {
        let shouldBecomeFirstResponder: Bool
        let placeholder: String
        let text: Binding<String>
        var accessibilityIdentifier: String?
        var onEditingChanged: (Bool) -> Void = { _ in }
        var onCommit: () -> Void = {}

        @FocusState private var focusedField: Field?

        var body: some View {
            SecureField(
                placeholder,
                text: text,
                onCommit: onCommit
            )
            .accessibilityIdentifier(accessibilityIdentifier)
            .focused($focusedField, equals: .secure)
            .keyboardType(.default)
            .writingToolsBehaviorDisabled()
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .onAppear(perform: onAppear)
        }

        private func onAppear() {
            if shouldBecomeFirstResponder {
                focusedField = .secure
            }
        }
    }
}
