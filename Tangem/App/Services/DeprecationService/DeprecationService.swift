//
//  DeprecationService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import UIKit

class DeprecationService {
    private let deprecatedVersionUpto = "15.5"
    private let osVersion = UIDevice.current.systemVersion

    private let warningAppearanceDayInterval = 7
    private let permanentWarningDate = DateComponents(calendar: Calendar(identifier: .gregorian), year: 2023, month: 2, day: 15).date!
    private let iOS13EndSupportDate = DateComponents(calendar: Calendar(identifier: .gregorian), year: 2023, month: 4, day: 1).date!

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = .current
        formatter.dateStyle = .long
        return formatter
    }()

    private var osDeprecationWarning: WarningEvent? {
        guard osDeprecated else {
            return nil
        }

        let currentDate = Date()
        guard
            currentDate < permanentWarningDate,
            currentDate < iOS13EndSupportDate
        else {
            return .osDeprecationPermanent(
                dateFormatter.string(from: iOS13EndSupportDate)
            )
        }

        if let dismissDate = AppSettings.shared.osDeprecationWarningDismissDate,
           let nextWarningAppearanceDate = Calendar.current.date(byAdding: .day, value: warningAppearanceDayInterval, to: dismissDate),
           currentDate < nextWarningAppearanceDate {
            return nil
        }

        return .osDeprecationTemporary
    }

    private var appDeprecationWarning: WarningEvent? {
        // [REDACTED_TODO_COMMENT]
        nil
    }
}

extension DeprecationService: DeprecationServicing {
    var deprecationWarnings: [WarningEvent] {
        var events = [WarningEvent]()
        osDeprecationWarning.map { events.append($0) }
        appDeprecationWarning.map { events.append($0) }
        return events
    }

    var osDeprecated: Bool {
        osVersion > deprecatedVersionUpto ? false : true
    }

    func userDismissOSDeprecationWarning() {
        AppSettings.shared.osDeprecationWarningDismissDate = Date()
    }
}
