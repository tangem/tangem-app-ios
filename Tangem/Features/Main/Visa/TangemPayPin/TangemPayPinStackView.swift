//
//  TangemPayPinStackView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct TangemPayPinStackView: View {
    @Binding var pinText: String
    let length: Int
    var errorMessage: String? = nil
    var isDisabled: Bool = false

    @State private var isResponder: Bool? = false

    var body: some View {
        VStack(spacing: DesignSystem.Tokens.Spacing.s150) {
            ZStack {
                if !isDisabled {
                    backgroundField.opacity(0)
                }

                HStack(spacing: DesignSystem.Tokens.Spacing.s100) {
                    ForEach(0 ..< length, id: \.self) { index in
                        box(at: index)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    isResponder = !isDisabled
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .style(DesignSystem.Tokens.Font.Caption.medium, color: DesignSystem.Tokens.Theme.Text.Status.error)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .screenCaptureProtection()
        .fixedSize(horizontal: false, vertical: true)
        .onChange(of: isDisabled) { isResponder = !$0 }
        .onDidAppear { isResponder = !isDisabled }
        .onWillDisappear { isResponder = false }
    }

    private func box(at index: Int) -> some View {
        RoundedRectangle(cornerRadius: DesignSystem.Tokens.CornerRadius._200, style: .continuous)
            .fill(DesignSystem.Tokens.Theme.Bg.Opaque.primary)
            .frame(width: DesignSystem.Tokens.Size.s700, height: DesignSystem.Tokens.Size.s800)
            .overlay {
                Text(digit(at: index))
                    .style(DesignSystem.Tokens.Font.Heading.medium, color: DesignSystem.Tokens.Theme.Text.primary)
            }
            .overlay {
                RoundedRectangle(cornerRadius: DesignSystem.Tokens.CornerRadius._200, style: .continuous)
                    .strokeBorder(borderColor(at: index), lineWidth: DesignSystem.Tokens.BorderWidth.sm)
            }
    }

    private func borderColor(at index: Int) -> Color {
        if errorMessage != nil {
            return DesignSystem.Tokens.Theme.Border.Status.error
        }

        if !isDisabled, index == pinText.count {
            return DesignSystem.Tokens.Theme.Border.Status.info
        }

        return DesignSystem.Tokens.Theme.Border.secondary
    }

    private func digit(at index: Int) -> String {
        let characters = Array(pinText)
        return characters.indices.contains(index) ? String(characters[index]) : ""
    }

    private var backgroundField: some View {
        CustomTextField(
            text: $pinText,
            isResponder: $isResponder,
            actionButtonTapped: .constant(false),
            handleKeyboard: true,
            keyboard: .numberPad,
            placeholder: "",
            maxCount: length
        )
        .setAutocapitalizationType(.none)
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    VStack(spacing: DesignSystem.Tokens.Spacing.s500) {
        TangemPayPinStackView(pinText: .constant("12"), length: 4)
        TangemPayPinStackView(pinText: .constant("1234"), length: 4, errorMessage: "Codes don't match. Try again")
        TangemPayPinStackView(pinText: .constant("0000"), length: 4, isDisabled: true)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DesignSystem.Tokens.Theme.Bg.primary)
}
#endif // DEBUG
