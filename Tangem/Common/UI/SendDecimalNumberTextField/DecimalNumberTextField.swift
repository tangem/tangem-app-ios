//
//  DecimalNumberTextField.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

struct DecimalNumberTextField: View {
    // Public
    @ObservedObject private var stateObject: StateObject

    // Septupable properties
    private var placeholder: String = "0"
    private var appearance: Appearance = .init()

    // Internal state
    @State private var textFieldText: String = ""
    @State private var size: CGSize = .zero

    init(stateObject: StateObject) {
        self.stateObject = stateObject
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
            .tint(appearance.textColor)
            .labelsHidden()
            .keyboardType(.decimalPad)
            .onChange(of: stateObject.decimalValue) { newDecimalValue in
                switch newDecimalValue {
                case .none, .internal:
                    // Do nothing. Because all internal values already updated
                    break
                case .external(let value):
                    // If the decimalValue did updated from external place
                    // We have to update the private values
                    let formattedNewValue = stateObject.format(value: value)
                    updateValues(with: formattedNewValue)
                }
            }
            .onChange(of: textFieldText) { newValue in
                updateValues(with: newValue)
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
        let decimalSeparator = stateObject.decimalSeparator()

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
        numberString = stateObject.format(value: numberString)

        // Update private `@State` for display not correct number, like 0,000
        textFieldText = numberString

        if let value = stateObject.mapToDecimal(string: numberString) {
            stateObject.update(decimalValue: .internal(value))
        } else if numberString.isEmpty {
            stateObject.update(decimalValue: nil)
        }
    }
}

// MARK: - Setupable

extension DecimalNumberTextField: Setupable {
    func placeholder(_ placeholder: String) -> Self {
        map { $0.placeholder = placeholder }
    }

    func appearance(_ appearance: Appearance) -> Self {
        map { $0.appearance = appearance }
    }
}

struct DecimalNumberTextField_Previews: PreviewProvider {
    static var previews: some View {
        DecimalNumberTextField(stateObject: .init(maximumFractionDigits: 8))
    }
}

// MARK: - StateObject

extension DecimalNumberTextField {
    class StateObject: ObservableObject {
        // Public properties
        var value: Decimal? {
            decimalValue?.value
        }

        var valuePublisher: AnyPublisher<Decimal?, Never> {
            $decimalValue
                .removeDuplicates { $0?.value == $1?.value }
                // We skip the first nil value from the text field
                .dropFirst()
                // If value == nil then continue chain to reset states to idle
                .filter { $0 == nil || $0?.isInternal == true }
                .map { $0?.value }
                .eraseToAnyPublisher()
        }

        // Fileprivate
        @Published fileprivate var decimalValue: DecimalValue?

        // Private
        private let decimalNumberFormatter: DecimalNumberFormatter

        init(maximumFractionDigits: Int) {
            decimalNumberFormatter = .init(maximumFractionDigits: maximumFractionDigits)
        }

        // MARK: - Public

        func update(maximumFractionDigits: Int) {
            decimalNumberFormatter.update(maximumFractionDigits: maximumFractionDigits)
        }

        /// Use this method for `external` update the `decimalValue`
        func update(value: Decimal?) {
            guard let value else {
                decimalValue = nil
                return
            }

            decimalValue = .external(value)
        }

        // MARK: - Fileprivate only for DecimalNumberTextField

        fileprivate func decimalSeparator() -> Character {
            decimalNumberFormatter.decimalSeparator
        }

        fileprivate func format(value: String) -> String {
            decimalNumberFormatter.format(value: value)
        }

        fileprivate func format(value: Decimal) -> String {
            decimalNumberFormatter.format(value: value)
        }

        fileprivate func mapToDecimal(string: String) -> Decimal? {
            decimalNumberFormatter.mapToDecimal(string: string)
        }

        fileprivate func update(decimalValue value: DecimalValue?) {
            guard let value else {
                decimalValue = nil
                return
            }

            decimalValue = value
        }
    }
}

// MARK: - Appearance

extension DecimalNumberTextField {
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

// MARK: - DecimalValue

extension DecimalNumberTextField.StateObject {
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
