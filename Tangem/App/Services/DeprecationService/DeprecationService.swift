//
//  DeprecationService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import UIKit

class DeprecationService {
    private let firstSupportedOperatingSystemVersion = "14.6"
    private let opearingSystemVersion = UIDevice.current.systemVersion

    private let daysBetweenWarnings = 7
    private let permanentDeprecationWarningDate = DateComponents(calendar: Calendar(identifier: .gregorian), year: 2023, month: 2, day: 15).date!
    private let operatingSystemDeprecationDate = DateComponents(calendar: Calendar(identifier: .gregorian), year: 2023, month: 4, day: 1).date!

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = .current
        formatter.dateStyle = .long
        return formatter
    }()

    private var osDeprecationWarning: WarningEvent? {
        guard operatingSystemDeprecated else {
            return nil
        }

        let currentDate = Date()
        guard currentDate < permanentDeprecationWarningDate else {
            return .osDeprecationPermanent(
                dateFormatter.string(from: operatingSystemDeprecationDate)
            )
        }

        if let dismissalDate = AppSettings.shared.osDeprecationWarningDismissalDate,
           let nextWarningAppearanceDate = Calendar.current.date(byAdding: .day, value: daysBetweenWarnings, to: dismissalDate),
           currentDate < nextWarningAppearanceDate {
            return nil
        }

        return .osDeprecationTemporary
    }

    private var appDeprecationWarning: WarningEvent? {
        // [REDACTED_TODO_COMMENT]
        nil
    }

    init() {
        if permanentDeprecationWarningDate >= operatingSystemDeprecationDate {
            assertionFailure("Permanent deprecation warning date should be before actual OS deprecation date")
        }
    }
}

extension DeprecationService: DeprecationServicing {
    var deprecationWarnings: [WarningEvent] {
        var events = [WarningEvent]()
        osDeprecationWarning.map { events.append($0) }
        appDeprecationWarning.map { events.append($0) }
        return events
    }

    var operatingSystemDeprecated: Bool {
        opearingSystemVersion < firstSupportedOperatingSystemVersion
    }

    func didDismissOSDeprecationWarning() {
        AppSettings.shared.osDeprecationWarningDismissalDate = Date()
    }
}
