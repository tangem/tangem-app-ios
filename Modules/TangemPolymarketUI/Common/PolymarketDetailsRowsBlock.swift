//
//  PolymarketDetailsRowsBlock.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

public struct PolymarketDetailsRowsBlock: View {
    private let rows: [Row]

    public init(rows: [Row]) {
        self.rows = rows
    }

    public var body: some View {
        VStack(spacing: 0) {
            ForEach(rows) { row in
                TangemUI.Row(title: row.title, subtitle: row.subtitle, value: row.value, subvalue: row.subvalue)
                    .valueAccessory { valueAccessory(for: row) }
                    .overrideTextColors(.init(value: DesignSystem.Color.textSecondary))
                    .showDivider(row.id != rows.last?.id)
            }
        }
    }

    @ViewBuilder
    private func valueAccessory(for row: Row) -> some View {
        if row.hasHint {
            PolymarketHintIcon(asset: DesignSystem.Icons.Info.regular16)
        }
    }
}

// MARK: - Row

public extension PolymarketDetailsRowsBlock {
    struct Row: Hashable, Identifiable {
        public let title: String
        public let subtitle: String?
        public let value: String
        public let subvalue: String?
        public let hasHint: Bool

        public var id: String { title }

        public init(
            title: String,
            subtitle: String? = nil,
            value: String,
            subvalue: String? = nil,
            hasHint: Bool = false
        ) {
            self.title = title
            self.subtitle = subtitle
            self.value = value
            self.subvalue = subvalue
            self.hasHint = hasHint
        }
    }
}
