//
//  StatusIcon+Modifiers.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils

// MARK: - Setupable Modifiers

public extension StatusIcon {
    func tint(_ color: Color) -> Self {
        map { $0.tint = color }
    }

    func size(_ side: CGFloat) -> Self {
        updatingScaledSide(side)
    }

    func glow(_ isEnabled: Bool = true) -> Self {
        map { $0.isGlowEnabled = isEnabled }
    }

    func animated(_ isAnimated: Bool = true) -> Self {
        map { $0.isAnimated = isAnimated }
    }

    func startDelay(_ delay: TimeInterval) -> Self {
        map { $0.startDelay = delay }
    }
}
