//
//  LinearGradient+Tangem.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

// MARK: - Tangem Linear gradients

public extension LinearGradient {
    enum Tangem {
        public enum Common {}
    }
}

// MARK: - Common

public extension LinearGradient.Tangem.Common {
    static let purplePink = LinearGradient(
        colors: [Color(hex: "#A3A0FF"), Color(hex: "#F79DFF")],
        startPoint: .leading, endPoint: .trailing
    )

    static let tokenDetailsMarketPrice = LinearGradient(
        colors: [
            Color.clear,
            Color.dynamic(light: Color(hex: "0F0F0F").opacity(0.2), dark: Color(hex: "0F0F0F").opacity(0.8)),
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}
