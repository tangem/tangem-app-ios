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

    private let placeholder: String = "0"
    private var decimalNumberFormatter: DecimalNumberFormatter
    private let font: Font
    private var decimalSeparator: Character { decimalNumberFormatter.decimalSeparator }
    private var groupingSeparator: Character { decimalNumberFormatter.groupingSeparator }

    init(
        decimalValue: Binding<DecimalValue?>,
        decimalNumberFormatter: DecimalNumberFormatter,
        font: Font
    ) {
        _decimalValue = decimalValue
        self.decimalNumberFormatter = decimalNumberFormatter
        self.font = font
    }

    var body: some View {
        TextField(placeholder, text: $textFieldText)
            .style(font, color: Colors.Text.primary1)
            .keyboardType(.decimalPad)
            .tintCompat(Colors.Text.primary1)
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
}

struct DecimalNumberTextField_Previews: PreviewProvider {
    @State private static var decimalValue: DecimalNumberTextField.DecimalValue?

    static var previews: some View {
        DecimalNumberTextField(
            decimalValue: $decimalValue,
            decimalNumberFormatter: DecimalNumberFormatter(maximumFractionDigits: 8),
            font: Fonts.Regular.title1
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
}
