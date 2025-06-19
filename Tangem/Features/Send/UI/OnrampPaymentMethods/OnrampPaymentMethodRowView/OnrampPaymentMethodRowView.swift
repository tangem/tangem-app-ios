//
//  OnrampPaymentMethodRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct OnrampPaymentMethodRowView: SelectableSectionRow {
    var isSelected: Bool
    let data: OnrampPaymentMethodRowViewData

    var body: some View {
        Button(action: data.action) {
            content
        }
        .buttonStyle(.plain)
    }

    private var content: some View {
        HStack(spacing: 12) {
            OnrampPaymentMethodIconView(url: data.iconURL)

            titleView

            Spacer()
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 14)
        .overlay {
            if isSelected { SelectionOverlay() }
        }
        .contentShape(Rectangle())
    }

    private var titleView: some View {
        Text(data.name)
            .style(
                Fonts.Bold.subheadline,
                color: isSelected ? Colors.Text.primary1 : Colors.Text.secondary
            )
            .lineLimit(1)
    }
}

#Preview {
    OnrampPaymentMethodRowView(isSelected: true, data: .init(id: "card", name: "Card", iconURL: nil, action: {}))
}
