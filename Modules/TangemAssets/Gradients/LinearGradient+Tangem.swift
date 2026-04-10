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
}
