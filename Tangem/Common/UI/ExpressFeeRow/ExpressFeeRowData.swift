//
//  ExpressFeeRowData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct ExpressFeeRowData: Identifiable {
    var id: Int { hashValue }

    let title: String
    let subtitle: LoadableTextView.State
    let action: (() -> Void)?

    init(title: String, subtitle: LoadableTextView.State, action: (() -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }
}

extension ExpressFeeRowData: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(subtitle)
    }

    static func == (lhs: ExpressFeeRowData, rhs: ExpressFeeRowData) -> Bool {
        lhs.id == rhs.id
    }
}
