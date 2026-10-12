//
//  TangemPayFormFieldView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct TangemPayFormFieldView: View {
    @Binding var field: TangemPayFormField

    let focused: FocusState<TangemPayFormField.ID?>.Binding

    private var isFieldFocused: Bool {
        focused.wrappedValue == field.id
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.inputToErrorSpacing) {
            input

            if let error = field.error {
                Text(error.message)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textStatusError)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - Subviews

private extension TangemPayFormFieldView {
    @ViewBuilder
    var input: some View {
        if let onSelect = field.onSelect {
            inputContent
                .contentShape(.rect)
                .onTapGesture {
                    focused.wrappedValue = nil
                    onSelect()
                }
        } else {
            inputContent
        }
    }

    var inputContent: some View {
        VStack(alignment: .leading, spacing: Constants.labelToValueSpacing) {
            label

            textField
        }
        .padding(.vertical, Constants.verticalPadding)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(dividerColor)
                .frame(height: Constants.dividerHeight)
        }
    }

    var label: some View {
        Text(field.title)
            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
    }

    var textField: some View {
        HStack(spacing: .zero) {
            TextField("", text: $field.text, prompt: Text(field.placeholder))
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                .focused(focused, equals: field.id)
                .keyboardType(field.id.keyboardType)
                .textContentType(field.id.textContentType)
                .textInputAutocapitalization(field.id.autocapitalization)
                .autocorrectionDisabled()
                .tint(DesignSystem.Color.textPrimary)
                .disabled(field.isSelectable)
                .allowsHitTesting(!field.isSelectable)

            Spacer(minLength: Constants.clearButtonSpacing)

            if field.isSelectable {
                DesignSystem.Icons.ChevronDown.regular20.image
                    .renderingMode(.template)
                    .foregroundStyle(DesignSystem.Color.iconSecondary)
            } else if !field.text.isEmpty, isFieldFocused {
                SwiftUI.Button {
                    field.text = ""
                } label: {
                    Assets.clear.image
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: Constants.clearIconSize, height: Constants.clearIconSize)
                        .foregroundStyle(DesignSystem.Color.iconTertiary)
                }
            }
        }
        .frame(height: Constants.valueHeight)
    }

    var dividerColor: Color {
        if isFieldFocused {
            return DesignSystem.Color.borderBrand
        }

        return field.error == nil ? DesignSystem.Color.borderTertiary : DesignSystem.Color.borderStatusError
    }
}

// MARK: - Constants

private extension TangemPayFormFieldView {
    enum Constants {
        static let verticalPadding: CGFloat = 12
        static let inputToErrorSpacing: CGFloat = 8
        static let labelToValueSpacing: CGFloat = 2
        static let valueHeight: CGFloat = 24
        static let dividerHeight: CGFloat = 1
        static let clearButtonSpacing: CGFloat = 12
        static let clearIconSize: CGFloat = 24
    }
}

// MARK: - Previews

@available(iOS 17.0, *)
#Preview {
    @Previewable @State var field = TangemPayFormField(
        id: .accountNumber,
        title: "Account number",
        placeholder: "0000000000",
        text: "00",
        error: nil
    )

    TangemPayFormFieldView(
        field: $field,
        focused: FocusState<TangemPayFormField.ID?>().projectedValue
    )
}
