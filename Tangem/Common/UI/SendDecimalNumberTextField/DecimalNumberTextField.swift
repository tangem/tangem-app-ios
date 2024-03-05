//
//  DecimalNumberTextField.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct DecimalNumberTextField: View {
    @Binding private var decimalValue: DecimalValue?
    @State private var textFieldText: String = ""
    @State private var size: CGSize = .zero

    private let placeholder: String = "0"
    private var decimalNumberFormatter: DecimalNumberFormatter
    private var appearance: Appearance = .init()

    private var decimalSeparator: Character { decimalNumberFormatter.decimalSeparator }
    private var groupingSeparator: Character { decimalNumberFormatter.groupingSeparator }

    init(
        decimalValue: Binding<DecimalValue?>,
        decimalNumberFormatter: DecimalNumberFormatter
    ) {
        _decimalValue = decimalValue
        self.decimalNumberFormatter = decimalNumberFormatter
    }

    var body: some View {
        ZStack(alignment: .leading) {
            Text(textFieldText.isEmpty ? placeholder : textFieldText)
                .font(appearance.font)
                .opacity(0)
                .layoutPriority(1)
                .readGeometry(\.frame.size, bindTo: $size)

            textField
                .frame(width: size.width)
        }
        .lineLimit(1)
    }

    private var textField: some View {
        TextField(text: $textFieldText, prompt: prompt, label: {})
            .style(appearance.font, color: appearance.textColor)
            .keyboardType(.decimalPad)
            .tint(Colors.Text.primary1)
            .onChange(of: decimalValue) { newDecimalValue in
                switch newDecimalValue {
                case .none, .internal:
                    // Do nothing. Because all internal values already updated
                    break
                case .external(let value):
                    // If the decimalValue did updated from external place
                    // We have to update the private values
                    let formattedNewValue = decimalNumberFormatter.format(value: value)
                    updateValues(with: formattedNewValue)
                }
            }
            .onChange(of: textFieldText) { newValue in
                updateValues(with: newValue)
            }
            .onAppear {
                if let value = _decimalValue.wrappedValue?.value {
                    textFieldText = decimalNumberFormatter.format(value: value)
                } else {
                    textFieldText = ""
                }
            }
    }

    private var prompt: Text {
        Text(placeholder)
            // We can't use .style(font:, color:) here because
            // We should have the `Text` type
            .font(appearance.font)
            .foregroundColor(appearance.placeholderColor)
    }

    private func updateValues(with newValue: String) {
        var numberString = newValue

        // If user start enter number with `decimalSeparator` add zero before it
        if numberString == String(decimalSeparator) {
            numberString.insert("0", at: numberString.startIndex)
        }

        // If user double tap on zero, add `decimalSeparator` to continue enter number
        if numberString == "00" {
            numberString.insert(decimalSeparator, at: numberString.index(before: numberString.endIndex))
        }

        // If text already have `decimalSeparator` remove last one
        if numberString.last == decimalSeparator,
           numberString.prefix(numberString.count - 1).contains(decimalSeparator) {
            numberString.removeLast()
        }

        // Format the string and reduce the tail
        numberString = decimalNumberFormatter.format(value: numberString)

        // Update private `@State` for display not correct number, like 0,000
        textFieldText = numberString

        if let value = decimalNumberFormatter.mapToDecimal(string: numberString) {
            decimalValue = .internal(value)
        } else if numberString.isEmpty {
            decimalValue = nil
        }
    }
}

// MARK: - Setupable

extension DecimalNumberTextField: Setupable {
    func maximumFractionDigits(_ digits: Int) -> Self {
        map { $0.decimalNumberFormatter.update(maximumFractionDigits: digits) }
    }

    func appearance(_ appearance: Appearance) -> Self {
        map { $0.appearance = appearance }
    }
}

struct DecimalNumberTextField_Previews: PreviewProvider {
    @State private static var decimalValue: DecimalNumberTextField.DecimalValue?

    static var previews: some View {
        DecimalNumberTextField(
            decimalValue: $decimalValue,
            decimalNumberFormatter: DecimalNumberFormatter(maximumFractionDigits: 8)
        )
    }
}

extension DecimalNumberTextField {
    enum DecimalValue: Hashable {
        case `internal`(Decimal)
        case external(Decimal)

        var value: Decimal {
            switch self {
            case .internal(let value):
                return value
            case .external(let value):
                return value
            }
        }

        var isInternal: Bool {
            switch self {
            case .internal:
                return true
            case .external:
                return false
            }
        }
    }

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
