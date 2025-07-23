//
//  BadgeView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct BadgeView: View {
    let item: Item

    private var titleColor: Color {
        switch item.style {
        case .accent:
            Colors.Text.accent
        case .secondary:
            Colors.Text.secondary
        case .warning:
            Colors.Text.warning
        }
    }

    private var bgColor: Color {
        switch item.style {
        case .accent:
            Colors.Text.accent.opacity(0.1)
        case .secondary:
            Colors.Control.unchecked
        case .warning:
            Colors.Text.warning.opacity(0.1)
        }
    }

    var body: some View {
        Text(item.title)
            .style(Fonts.Bold.caption1, color: titleColor)
            .padding(.vertical, 4)
            .padding(.horizontal, 12)
            .background(bgColor)
            .clipShape(Capsule())
    }
}

extension BadgeView {
    struct Item: Hashable {
        let title: String
        let style: Style
    }

    enum Style {
        case accent
        case secondary
        case warning
    }
}
