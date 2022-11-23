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

    private var placeholder: String = "0"
    private var maximumFractionDigits: Int = 8
    private let numberFormatter: NumberFormatter = .grouped
    private let groupedNumberFormatter: GroupedNumberFormatter

    init(decimalValue: Binding<Decimal?>) {
        _decimalValue = decimalValue

        groupedNumberFormatter = GroupedNumberFormatter(
            maximumFractionDigits: maximumFractionDigits,
            numberFormatter: numberFormatter
        )
    }

    private var textFieldProxyBinding: Binding<String> {
        Binding<String>(
            get: { groupedNumberFormatter.format(from: textFieldText) },
            set: { newValue in
                guard Decimal(string: newValue) != nil else { return }

                // Remove space separators for formatter correct work
                var numberString = newValue.replacingOccurrences(of: " ", with: "")

                // If user double tap on zero, add "," to continue enter number
                if numberString == "00" {
                    numberString.insert(",", at: numberString.index(before: numberString.endIndex))
                }

                // If user start enter number with "," add zero before comma
                if numberString == "," {
                    numberString.insert("0", at: numberString.startIndex)
                }

                // If text already have "," remove last one
                if numberString.last == ",",
                   numberString.prefix(numberString.count - 1).contains(",") {
                    numberString.removeLast()
                }

                // Update private @State for display not correct number, like 0,000
                textFieldText = numberString

                // If string is correct number, update binding for work external updates
                if let value = numberFormatter.number(from: numberString) {
                    decimalValue = value.decimalValue
                }
            }
        )
    }

    var body: some View {
        TextField(placeholder, text: textFieldProxyBinding)
            .style(Fonts.Regular.title1, color: Colors.Text.primary1)
            .keyboardType(.decimalPad)
    }
}

extension GroupedNumberTextField: Setupable {
    func maximumFractionDigits(_ digits: Int) -> Self {
        map { $0.maximumFractionDigits = digits }
    }
}

struct GroupedNumberTextField_Previews: PreviewProvider {
    @State private static var decimalValue: Decimal?

    static var previews: some View {
        GroupedNumberTextField(decimalValue: $decimalValue)
    }
}
