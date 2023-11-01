//
//  SendInputField.swift
//  Send
//
//  Created by [REDACTED_AUTHOR]
//

import SwiftUI

struct SendInputField: View {
    @Binding var text: String

    let placeholderText: String
    let currencyCode: String

    @State private var firstResponder: Bool? = true

    private let placeholderColor = Color.gray.opacity(0.6) // [REDACTED_TODO_COMMENT]

    @State private var size: CGSize = .zero

    var body: some View {
        HStack(spacing: 5) {
            Spacer(minLength: 0)

            ZStack {
                ZStack {
                    placeholderTextView

                    inputField
                        .frame(maxWidth: size.width)
                }

                ZStack {
                    Text(text)
                    Text(placeholderText)
                }
                .font(.system(size: 28))
                .multilineTextAlignment(.leading)
                .lineLimit(1)
                .offset(y: 10)
                .opacity(0)
                .readGeometry(\.size, bindTo: $size)
            }

            Text(currencyCode)
                .foregroundColor(text.isEmpty ? placeholderColor : .black)
                .lineLimit(1)
                .layoutPriority(1)

            Spacer(minLength: 0)
        }
        .font(.system(size: 28))
        .onAppear {
            setFirstResponser(true)
        }
    }

    @ViewBuilder
    private var inputField: some View {
        CustomTextField(
            text: $text,
            isResponder: $firstResponder,
            actionButtonTapped: Binding.constant(false),
            handleKeyboard: false,
            keyboard: .decimalPad,
            font: .systemFont(ofSize: 28),
            placeholder: ""
        )
    }

    private var placeholderTextView: some View {
        Text(placeholderText)
            .lineLimit(1)
            .foregroundColor(placeholderColor)
            .font(.system(size: 28))
            .opacity(text.isEmpty ? 1 : 0)
    }

    private func setFirstResponser(_ value: Bool) {
        firstResponder = value
    }
}

#Preview {
    SendInputField(text: .constant(""), placeholderText: "0,00", currencyCode: "USDT")
        .padding()
}
