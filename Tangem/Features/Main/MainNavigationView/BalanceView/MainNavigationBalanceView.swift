//
//  MainNavigationBalanceView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct MainNavigationBalanceView: View {
    private let state: MainNavigationBalanceState
    private let style: Style
    private let accessibilityIdentifier: String?

    init(
        state: MainNavigationBalanceState,
        style: Style,
        accessibilityIdentifier: String? = nil
    ) {
        self.state = state
        self.style = style
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    var body: some View {
        switch state {
        case .loading(.some(let text)):
            textView(text)
        case .loaded(let text):
            textView(text)
        case .loading(.none), .empty:
            EmptyView()
        }
    }
}

// MARK: - Subviews

private extension MainNavigationBalanceView {
    func textView(_ text: SensitiveText.TextType) -> some View {
        SensitiveText(text)
            .style(style.font, color: style.textColor)
            .accessibilityIdentifier(accessibilityIdentifier)
    }
}

// MARK: - Types

extension MainNavigationBalanceView {
    struct Style {
        public let font: Font
        public let textColor: Color

        public init(font: Font, textColor: Color) {
            self.font = font
            self.textColor = textColor
        }
    }
}
