//
//  TangemPayOrderCardDataFieldView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct TangemPayOrderCardDataFieldView: View {
    @Binding var field: TangemPayOrderCardDataField
    @Binding var focusedField: TangemPayOrderCardDataField.ID?

    let nextFieldID: TangemPayOrderCardDataField.ID?
    let reservesErrorSpace: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.inputToErrorSpacing) {
            input

            errorLabel
        }
    }

    @ViewBuilder
    private var errorLabel: some View {
        if field.error != nil || reservesErrorSpace {
            Text(field.error?.message ?? " ")
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textStatusError)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(field.error == nil ? 0 : 1)
        }
    }

    private var input: some View {
        VStack(alignment: .leading, spacing: Constants.labelToValueSpacing) {
            label
            value
        }
        .padding(.vertical, Constants.verticalPadding)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(dividerColor)
                .frame(height: Constants.dividerHeight)
        }
    }

    private var label: some View {
        HStack(spacing: Constants.labelSpacing) {
            Text(field.title)
                .style(DesignSystem.Font.captionMediumToken, color: labelColor)

            if field.isOptional {
                Text(Constants.optionalPrefix + Localization.tangempayOrderDataFieldOptional)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textTertiary)
            }
        }
        .lineLimit(1)
        .frame(height: Constants.labelHeight)
    }

    private var value: some View {
        textField
            .frame(height: Constants.valueHeight)
    }

    private var textField: some View {
        TangemPayOrderCardTextField(
            text: $field.text,
            focusedField: $focusedField,
            field: field,
            mask: field.inputMask,
            nextFieldID: nextFieldID,
            textColor: valueColor
        )
    }

    private var labelColor: Color {
        field.isEditable ? DesignSystem.Color.textSecondary : DesignSystem.Color.textTertiary
    }

    private var valueColor: Color {
        field.isEditable ? DesignSystem.Color.textPrimary : DesignSystem.Color.textTertiary
    }

    private var dividerColor: Color {
        field.error == nil ? DesignSystem.Color.borderTertiary : DesignSystem.Color.borderStatusError
    }
}

private extension TangemPayOrderCardDataFieldView {
    enum Constants {
        static let verticalPadding: CGFloat = 12
        static let inputToErrorSpacing: CGFloat = 8
        static let labelHeight: CGFloat = 16
        static let labelSpacing: CGFloat = 4
        static let labelToValueSpacing: CGFloat = 2
        static let valueHeight: CGFloat = 24
        static let dividerHeight: CGFloat = 1
        static let optionalPrefix = "• "
    }
}
