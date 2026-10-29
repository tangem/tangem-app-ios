//
//  PolymarketActivitySection.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemPolymarket
import TangemPolymarketUI

struct PolymarketActivitySection: Identifiable, Hashable {
    let id: Date
    let title: String
    let rows: [PolymarketActivityRow.Model]
}

// MARK: - Grouping

extension PolymarketActivitySection {
    static func make(records: [PolymarketActivityRecord], calendar: Calendar = .current) -> [PolymarketActivitySection] {
        let grouped = records.reduce(into: [(day: Date, records: [PolymarketActivityRecord])]()) { sections, record in
            let day = calendar.startOfDay(for: record.occurredAt)

            if let index = sections.lastIndex(where: { $0.day == day }) {
                sections[index].records.append(record)
            } else {
                sections.append((day: day, records: [record]))
            }
        }

        return grouped.map { section in
            PolymarketActivitySection(
                id: section.day,
                title: title(for: section.day, calendar: calendar),
                rows: section.records.map(PolymarketActivityRow.Model.make(record:))
            )
        }
    }

    private static func title(for day: Date, calendar: Calendar) -> String {
        guard !calendar.isDateInToday(day) else { return Localization.commonToday }

        return dayFormatter.string(from: day)
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
}
