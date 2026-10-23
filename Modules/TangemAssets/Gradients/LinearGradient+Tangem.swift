//
//  LinearGradient+Tangem.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import struct SwiftUI.Color
public import struct SwiftUI.LinearGradient

// MARK: - Tangem Linear gradients

public extension LinearGradient {
    enum Tangem {
        public enum Common {}
    }
}

// MARK: - Common

public extension LinearGradient.Tangem.Common {
    static let tokenDetailsMarketPrice = LinearGradient(
        colors: [
            Color.clear,
            Color.dynamic(light: Color(hex: "0F0F0F").opacity(0.2), dark: Color(hex: "0F0F0F").opacity(0.8)),
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}
