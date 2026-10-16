//
//  NewsWidgetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

/// Single source of truth for the "Tangem AI" brand gradient (#7b78ff → #c56bcd with the stop at 43.125% per Figma).
enum NewsHeaderGradient {
    static let stops: [Gradient.Stop] = [
        .init(color: Color(red: 0x7b / 255, green: 0x78 / 255, blue: 0xff / 255), location: 0),
        .init(color: Color(red: 0xc5 / 255, green: 0x6b / 255, blue: 0xcd / 255), location: 0.43125),
    ]

    static let linearGradient = LinearGradient(stops: stops, startPoint: .leading, endPoint: .trailing)
}
