//
//  View+Overlays.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    func foregroundOverlay<S: ShapeStyle>(_ style: S) -> some View {
        modifier(ForegroundOverlayModifier(style: style))
    }
}
