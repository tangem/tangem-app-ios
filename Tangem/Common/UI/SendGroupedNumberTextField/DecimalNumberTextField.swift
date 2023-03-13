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
    private var decimalSeparator: Character { decimalNumberFormatter.decimalSeparator }
    private var groupingSeparator: Character { decimalNumberFormatter.groupingSeparator }

    init(
        decimalValue: Binding<DecimalValue?>,
        decimalNumberFormatter: DecimalNumberFormatter
    ) {
        _decimalValue = decimalValue
        self.decimalNumberFormatter = decimalNumberFormatter
    }

    private var textFieldProxyBinding: Binding<String> {
        Binding<String>(
            get: { decimalNumberFormatter.format(value: textFieldText) },
            set: { updateValues(with: $0) }
        )
    }

    var body: some View {
        TextField(placeholder, text: textFieldProxyBinding)
            .style(Fonts.Regular.title1, color: Colors.Text.primary1)
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
    }

    private func updateValues(with newValue: String) {
        // Remove space separators for formatter correct work
        var numberString = newValue // .replacingOccurrences(of: groupingSeparator, with: "")

        // If user start enter number with `decimalSeparator` add zero before it
        if numberString == String(decimalSeparator) {
            numberString.insert("0", at: numberString.startIndex)
        }

        // If user double tap on zero, add `decimalSeparator` to continue enter number
        if numberString == "00" {
            numberString.insert(decimalSeparator, at: numberString.index(before: numberString.endIndex))
        }

        // Continue if the field is empty. The field supports only decimal values
        guard numberString.isEmpty || Decimal(string: numberString) != nil else { return }

        // If text already have `decimalSeparator` remove last one
        if numberString.last == decimalSeparator,
           numberString.prefix(numberString.count - 1).contains(decimalSeparator) {
            numberString.removeLast()
        }

        // Update private `@State` for display not correct number, like 0,000
        textFieldText = numberString

        // Format string to reduce digits
//        var formattedValue = decimalNumberFormatter.format(value: numberString)

        if var value = decimalNumberFormatter.mapToDecimal(string: numberString) {
            value.round(
                scale: decimalNumberFormatter.maximumFractionDigits,
                roundingMode: decimalNumberFormatter.roundingMode
            )
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
}
