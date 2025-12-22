//
//  AppsFlyerAnalyticsEventConverter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

enum AppsFlyerAnalyticsEventConverter {
    private static let decimalFormatter: DecimalNumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = .posixEnUS
        numberFormatter.usesGroupingSeparator = false
        numberFormatter.decimalSeparator = "."

        return DecimalNumberFormatter(
            numberFormatter: numberFormatter,
            maximumFractionDigits: Limits.numberDecimalPrecision
        )
    }()

    static func convert(event: String) -> String {
        event.trim(toLength: Limits.eventNameLength)
    }

    static func convert(params: [String: Any]) -> [String: Any] {
        params.reduce(into: [:]) { result, element in
            let convertedKey = convert(parameterKey: element.key)
            let convertedValue = convert(parameterValue: element.value)
            result[convertedKey] = convertedValue
        }
    }

    private static func convert(parameterKey: String) -> String {
        parameterKey.toUnderscoreCase().trim(toLength: Limits.eventParameterKeyLength)
    }

    private static func convert(parameterValue: Any) -> Any {
        switch parameterValue {
        case is Bool:
            parameterValue

        case is any BinaryInteger:
            parameterValue

        case let floatingValue as any BinaryFloatingPoint where floatingValue.isFinite:
            decimalFormatter.format(value: String(Double(floatingValue)))

        case let decimalValue as Decimal:
            decimalFormatter.format(value: decimalValue)

        case let stringValue as String:
            if let decimalValue = Decimal(string: stringValue) {
                decimalFormatter.format(value: decimalValue)
            } else {
                stringValue.trim(toLength: Limits.eventParameterValueLength)
            }

        default:
            String(describing: parameterValue).trim(toLength: Limits.eventParameterValueLength)
        }
    }
}

extension AppsFlyerAnalyticsEventConverter {
    // [REDACTED_TODO_COMMENT]
    private enum Limits {
        static let eventNameLength = 100
        static let eventParameterKeyLength = 100
        static let eventParameterValueLength = 1000
        static let numberDecimalPrecision = 5
    }
}
