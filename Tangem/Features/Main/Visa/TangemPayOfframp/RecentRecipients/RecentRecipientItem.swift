//
//  RecentRecipientItem.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct RecentRecipientItem: Identifiable {
    let id: String
    let monogram: String
    let name: String
    let accountNumber: String
}

// MARK: - Previews

#if DEBUG
extension RecentRecipientItem {
    static let previewList = [
        RecentRecipientItem(
            id: "company",
            monogram: "A",
            name: "Company LLC",
            accountNumber: "1234567890"
        ),
        RecentRecipientItem(
            id: "johny",
            monogram: "D",
            name: "Johny Johnson",
            accountNumber: "9087654321"
        ),
        RecentRecipientItem(
            id: "svetlana-ivanova",
            monogram: "S",
            name: "Svetlana Ivanova",
            accountNumber: "5647382910"
        ),
    ]
}
#endif
