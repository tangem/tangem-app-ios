//
//  View+MCPIntentSheet.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

extension View {
    func mcpIntentSheetConfiguration() -> some View {
        floatingSheetConfiguration { configuration in
            configuration.backgroundInteractionBehavior = .consumeTouches
            configuration.sheetBackground = .color(DesignSystem.Color.bgPrimary)
        }
    }
}

extension Animation {
    static func mcpIntentIconsAppear(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .timingCurve(0.42, 0, 0.58, 1, duration: 0.2).delay(0.55)
    }
}
