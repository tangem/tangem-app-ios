//
//  OpenTelemetryNameConverter.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// `[Basic] Transaction sent` -> metric `transaction_sent` with `category` attribute `basic`. The
/// same derivation the Android app uses, so neither side needs a hand-written name per event.
enum OpenTelemetryNameConverter {
    struct Coordinates: Hashable {
        let metricName: String
        let category: String
    }

    /// `nil` for an event id without the `[Category] Name` shape.
    static func coordinates(for event: Analytics.Event) -> Coordinates? {
        guard let categoryRange = event.rawValue.firstRange(of: Constants.categoryPattern) else {
            return nil
        }

        let category = segment(event.rawValue[categoryRange])
        let metricName = segment(event.rawValue[categoryRange.upperBound...])

        guard !category.isEmpty, !metricName.isEmpty else {
            return nil
        }

        return Coordinates(metricName: metricName, category: category)
    }

    static func attributeName(for parameterKey: Analytics.ParameterKey) -> String {
        segment(parameterKey.rawValue[...])
    }

    private static func segment(_ raw: Substring) -> String {
        var segment = ""

        for character in raw.lowercased() {
            let isAllowed = character.isASCII && (character.isLowercase || character.isNumber)

            if isAllowed {
                segment.append(character)
            } else if segment.last != "_" {
                segment.append("_")
            }
        }

        return segment.trimmingCharacters(in: Constants.underscore)
    }
}

// MARK: - Constants

private extension OpenTelemetryNameConverter {
    enum Constants {
        static let categoryPattern = #/^\[[^\]]+\]/#
        static let underscore = CharacterSet(charactersIn: "_")
    }
}
