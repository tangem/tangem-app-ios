//
//  FirebaseAnalyticsEventConverter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// See the documentation for the `logEvent(_:parameters:)` method in the `FIRAnalytics.h` file for current
/// Firebase Analytics limitations and reasons why this converter is required.
enum FirebaseAnalyticsEventConverter {
    static func convert(event: String) -> String {
        return convert(string: event)
    }

    static func convert(params: [String: Any]) -> [String: Any] {
        return params.reduce(into: [:]) { result, element in
            let convertedKey = convert(string: element.key)
            let convertedValue = convert(value: element.value)
            result[convertedKey] = convertedValue
        }
    }

    private static func convert(string: String) -> String {
        string
            .toUnderscoreCase()
            .trim(toLength: Constants.firebaseEventNameMaxLength)
    }

    private static func convert(value: Any) -> Any {
        switch value {
        case let intValue as Int:
            return intValue
        case let doubleValue as Double:
            return doubleValue
        case let stringValue as String:
            return stringValue.trim(toLength: Constants.firebaseEventValueMaxLength)
        default:
            return String(describing: value).trim(toLength: Constants.firebaseEventValueMaxLength)
        }
    }
}

// MARK: - Constants

private extension FirebaseAnalyticsEventConverter {
    enum Constants {
        static let firebaseEventNameMaxLength = 40
        static let firebaseEventValueMaxLength = 100
    }
}
