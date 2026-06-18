//
//  View+LiquidGlass.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    var isLiquidGlassSupported: Bool {
        if #available(iOS 26.0, *) {
            true
        } else {
            false
        }
    }
}

public extension ViewModifier {
    var isLiquidGlassSupported: Bool {
        if #available(iOS 26.0, *) {
            true
        } else {
            false
        }
    }
}

public extension ToolbarContent {
    var isLiquidGlassSupported: Bool {
        if #available(iOS 26.0, *) {
            true
        } else {
            false
        }
    }
}
