//
//  DecimalNumberTextFieldViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation

class DecimalNumberTextFieldViewModel: ObservableObject {
    @Published var measuredTextSize: CGSize = .zero
    @Published private var textFieldText: String = ""

    lazy var textFieldTextBinding: BindingValue<String> = .init(
        root: self,
        default: "",
        get: { $0.textFieldText },
        set: { $0.textFieldTextDidChanged(newValue: $1) }
    )

    private let decimalNumberFormatter: DecimalNumberFormatter
    private let decimalValue = CurrentValueSubject<DecimalValue?, Never>(nil)
    private var bag: Set<AnyCancellable> = []

    init(maximumFractionDigits: Int) {
        decimalNumberFormatter = .init(maximumFractionDigits: maximumFractionDigits)
    }
}

// MARK: - Public

extension DecimalNumberTextFieldViewModel {
    var value: Decimal? {
        decimalValue.value?.value
    }

    var valuePublisher: AnyPublisher<Decimal?, Never> {
        decimalValue
            .removeDuplicates { $0?.value == $1?.value }
            // We skip the first nil value from the text field
            .dropFirst()
            // If value == nil then continue chain to reset states to idle
            .filter { $0 == nil || $0?.isInternal == true }
            .map { $0?.value }
            .eraseToAnyPublisher()
    }

    var debouncedValuePublisher: AnyPublisher<Decimal?, Never> {
        valuePublisher
            .flatMapLatest { value in
                if value == nil {
                    // Nil value will be emitted without debounce
                    return Just(value).eraseToAnyPublisher()
                }

                return Just(value)
                    // But if have the value we will wait a bit
                    .delay(for: 0.5, scheduler: DispatchQueue.global())
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func update(maximumFractionDigits: Int) {
        decimalNumberFormatter.update(maximumFractionDigits: maximumFractionDigits)
    }

    /// Use this method for `external` update the `decimalValue`
    func update(value: Decimal?) {
        switch value {
        case .none:
            // Update `textFieldText` to empty
            updateTextFieldText(with: "")
            decimalValue.send(nil)

        case .some(let value):
            // If the decimalValue was updated from external place
            // We have to update the private values
            let formattedNewValue: String = decimalNumberFormatter.format(value: value)
            updateTextFieldText(with: formattedNewValue)
            decimalValue.send(.external(value))
        }
    }
}

// MARK: - Private

private extension DecimalNumberTextFieldViewModel {
    func textFieldTextDidChanged(newValue: String) {
        let decimal = updateTextFieldText(with: newValue)
        decimalValue.send(decimal.map { .internal($0) })
    }

    @discardableResult
    func updateTextFieldText(with newValue: String) -> Decimal? {
        let decimalSeparator = decimalNumberFormatter.decimalSeparator

        var numberString = newValue

        if decimalNumberFormatter.isDecimal {
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
        }

        // Format the string and reduce the tail
        numberString = decimalNumberFormatter.format(value: numberString)

        // Keep the text in TextField correct for user but not decimal, like 0,000
        textFieldText = numberString

        let decimal = decimalNumberFormatter.mapToDecimal(string: numberString)
        return decimal
    }
}

// MARK: - DecimalValue

private extension DecimalNumberTextFieldViewModel {
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
