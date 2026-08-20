//
//  JointAccountMemberNameField.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

/// Underlined field for the name a member is known by inside the joint account, with the hint explaining it below.
struct JointAccountMemberNameField: View {
    @Binding private var text: String
    @FocusState.Binding private var isFocused: Bool

    /// The field measures itself differently once it has an editing session, which makes it grow on the first focus.
    /// Pinning the height to the line height the design gives the text keeps it still.
    @ScaledMetric(relativeTo: DesignSystem.Font.bodyMediumToken.relativeTo)
    private var textHeight = DesignSystem.Font.bodyMediumToken.lineHeight

    private let title: String
    private let maxLength: Int
    private let hasError: Bool

    init(
        text: Binding<String>,
        isFocused: FocusState<Bool>.Binding,
        title: String,
        maxLength: Int,
        hasError: Bool
    ) {
        _text = text
        _isFocused = isFocused
        self.title = title
        self.maxLength = maxLength
        self.hasError = hasError
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            textField

            Separator(color: separatorColor)
        }
        .infinityFrame(axis: .horizontal, alignment: .leading)
    }

    private var textField: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(token: DesignSystem.Font.captionMediumToken)
                .foregroundStyle(DesignSystem.Color.textSecondary)

            TextField("", text: $text)
                .font(token: DesignSystem.Font.bodyMediumToken)
                .foregroundStyle(DesignSystem.Color.textPrimary)
                .focused($isFocused)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onSubmit {
                    // Do NOT access SwiftUI internal state (@State, @FocusState, @Binding, @StateObject, etc) inside the `onSubmit(of:_:)` closure.
                    // This causes a memory leak as soon as the text field becomes the first responder.
                    // See https://stackoverflow.com/questions/70510596 and https://stackoverflow.com/questions/78763987 for more details
                    UIResponder.current?.resignFirstResponder()
                }
                // The field keeps its own buffer while it is being edited, so cutting the text off has to happen
                // after the update it typed, not from the setter of whatever it is bound to
                .onChange(of: text) { newValue in
                    text = String(newValue.prefix(maxLength))
                }
                .frame(height: textHeight)
                .padding(.vertical, 2)
        }
    }

    /// An unsupported character outweighs the focus: the field has to stay red while it is being corrected
    private var separatorColor: Color {
        if hasError {
            DesignSystem.Color.borderStatusError
        } else if isFocused {
            DesignSystem.Color.borderBrand
        } else {
            DesignSystem.Color.borderPrimary
        }
    }
}
