//
//  DeprecationService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import UIKit

class DeprecationService {
    private let firstSupportedSystemVersion = "16.0"
    private let systemVersion = UIDevice.current.systemVersion

    private let daysBetweenWarnings = 7
    private let permanentSystemDeprecationWarningDate = DateComponents(calendar: Calendar(identifier: .gregorian), year: 2025, month: 8, day: 1).date!
    private let systemDeprecationDate = DateComponents(calendar: Calendar(identifier: .gregorian), year: 2026, month: 1, day: 1).date!

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()

    private var systemDeprecated: Bool {
        systemVersion < firstSupportedSystemVersion
    }

    private var systemDeprecationWarning: GeneralNotificationEvent? {
        guard systemDeprecated else {
            return nil
        }

        let currentDate = Date()
        guard currentDate < permanentSystemDeprecationWarningDate else {
            return .systemDeprecationPermanent(
                dateFormatter.string(from: systemDeprecationDate)
            )
        }

        if let dismissalDate = AppSettings.shared.systemDeprecationWarningDismissalDate,
           let nextWarningAppearanceDate = Calendar.current.date(byAdding: .day, value: daysBetweenWarnings, to: dismissalDate),
           currentDate < nextWarningAppearanceDate {
            return nil
        }

        return .systemDeprecationTemporary
    }

    private var appDeprecationWarning: GeneralNotificationEvent? {
        // [REDACTED_TODO_COMMENT]
        nil
    }

    init() {
        assert(
            permanentSystemDeprecationWarningDate < systemDeprecationDate,
            "Permanent deprecation warning date should be before actual OS deprecation date"
        )
    }
}

extension DeprecationService: DeprecationServicing {
    var deprecationWarnings: [GeneralNotificationEvent] {
        [systemDeprecationWarning, appDeprecationWarning].compactMap { $0 }
    }

    func didDismissSystemDeprecationWarning() {
        AppSettings.shared.systemDeprecationWarningDismissalDate = Date()
    }
}
