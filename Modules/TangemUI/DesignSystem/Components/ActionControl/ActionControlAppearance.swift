//
//  ActionControlAppearance.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public enum ActionControlAppearance {
    static let dimmedOpacity: CGFloat = 0.4

    public static func contentColor(isEnabled: Bool) -> Color {
        isEnabled ? DesignSystem.Color.textPrimary : DesignSystem.Color.textTertiary
    }
}

public extension View {
    func actionControlDimmed(isEnabled: Bool) -> some View {
        opacity(isEnabled ? 1 : ActionControlAppearance.dimmedOpacity)
    }
}
