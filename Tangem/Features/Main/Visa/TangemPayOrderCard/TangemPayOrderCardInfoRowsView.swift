//
//  TangemPayOrderCardInfoRowsView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct TangemPayOrderCardInfoRowsView: View {
    let rows: [TangemPayOrderCardInfoRow]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                Row(title: row.title, subvalue: row.subvalue)
                    .valueAccessory { valueView(row) }
                    .verticalAlignment(.top)
                    .contentLead(.start)
                    .showDivider(index < rows.count - 1)
                    .disabled(row.isDimmed)
            }
        }
    }

    private func valueView(_ row: TangemPayOrderCardInfoRow) -> some View {
        HStack(spacing: Constants.badgeSpacing) {
            if let badge = row.badge {
                Badge(label: badge.text, accessibilityLabel: nil)
                    .size(.x4)
                    .appearance(badge.appearance)
            }

            if let value = row.value {
                Text(value)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
                    .lineLimit(1)
            }
        }
    }
}

private extension TangemPayOrderCardInfoRowsView {
    enum Constants {
        static let badgeSpacing: CGFloat = 8
    }
}
