//
//  PolymarketOrderBlockStyle.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

public enum PolymarketOrderBlockStyle: Hashable, Sendable {
    case regular
    case sheet

    public var background: Color {
        switch self {
        case .regular: DesignSystem.Color.bgSecondary
        case .sheet: DesignSystem.Color.bgTransparentPrimary
        }
    }

    var separatorInset: CGFloat {
        switch self {
        case .regular: 0
        case .sheet: 16
        }
    }

    var separatorHeight: Separator.Height {
        switch self {
        case .regular: .exact(1)
        case .sheet: .minimal
        }
    }
}

public struct PolymarketOrderBlockSeparator: View {
    private let style: PolymarketOrderBlockStyle

    public init(style: PolymarketOrderBlockStyle) {
        self.style = style
    }

    public var body: some View {
        Separator(height: style.separatorHeight, color: DesignSystem.Color.borderPrimary)
            .padding(.horizontal, style.separatorInset)
    }
}
