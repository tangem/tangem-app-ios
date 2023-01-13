//
//  GroupedNumberTextField.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct GroupedNumberTextField: View {
    @Binding private var decimalValue: Decimal?
    @State private var textFieldText: String = ""

    private let placeholder: String = "0"
    private var groupedNumberFormatter: GroupedNumberFormatter
    private var decimalSeparator: Character { groupedNumberFormatter.decimalSeparator }

    init(decimalValue: Binding<Decimal?>) {
        _decimalValue = decimalValue

        groupedNumberFormatter = GroupedNumberFormatter(numberFormatter: .grouped)
    }

    private var textFieldProxyBinding: Binding<String> {
        Binding<String>(
            get: { groupedNumberFormatter.format(from: textFieldText) },
            set: { newValue in
                // Remove space separators for formatter correct work
                var numberString = newValue.replacingOccurrences(of: " ", with: "")

                // If user start enter number with `decimalSeparator` add zero before comma
                if numberString == String(decimalSeparator) {
                    numberString.insert("0", at: numberString.startIndex)
                }

                // Continue if the field is empty. The field supports only decimal values
                guard numberString.isEmpty || Decimal(string: numberString) != nil else { return }

                // If user double tap on zero, add `decimalSeparator` to continue enter number
                if numberString == "00" {
                    numberString.insert(decimalSeparator, at: numberString.index(before: numberString.endIndex))
                }

                // If text already have `decimalSeparator` remove last one
                if numberString.last == decimalSeparator,
                   numberString.prefix(numberString.count - 1).contains(decimalSeparator) {
                    numberString.removeLast()
                }

                // Update private `@State` for display not correct number, like 0,000
                textFieldText = numberString

                // If string is correct number, update binding for work external updates
                if let value = groupedNumberFormatter.number(from: numberString) {
                    decimalValue = value.decimalValue
                } else if numberString.isEmpty {
                    decimalValue = nil
                }
            }
        )
    }

    var body: some View {
        TextField(placeholder, text: textFieldProxyBinding)
            .style(Fonts.Regular.title1, color: Colors.Text.primary1)
            .keyboardType(.decimalPad)
            .tintCompat(Colors.Text.primary1)
            .onChange(of: decimalValue) { decimalValue in
                guard let decimalValue else {
                    textFieldText = ""
                    return
                }

                let newValue = groupedNumberFormatter.format(from: decimalValue)
                if textFieldText != newValue {
                    textFieldText = newValue
                }
            }
    }
}

// MARK: - Setupable

extension GroupedNumberTextField: Setupable {
    func maximumFractionDigits(_ digits: Int) -> Self {
        map { $0.groupedNumberFormatter.update(maximumFractionDigits: digits) }
    }
}

struct GroupedNumberTextField_Previews: PreviewProvider {
    @State private static var decimalValue: Decimal?

    static var previews: some View {
        GroupedNumberTextField(decimalValue: $decimalValue)
    }
}
