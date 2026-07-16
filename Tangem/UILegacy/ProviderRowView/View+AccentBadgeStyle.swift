//
//  View+AccentBadgeStyle.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

extension View {
    func accentBadgeStyle() -> some View {
        padding(.vertical, 2)
            .padding(.horizontal, 6)
            .background(Colors.Icon.accent.opacity(0.1))
            .cornerRadiusContinuous(8)
    }
}
