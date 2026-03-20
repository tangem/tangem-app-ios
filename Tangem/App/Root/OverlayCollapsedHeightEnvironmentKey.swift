//
//  OverlayCollapsedHeightEnvironmentKey.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

private struct OverlayCollapsedHeightKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    var overlayCollapsedHeight: CGFloat {
        get { self[OverlayCollapsedHeightKey.self] }
        set { self[OverlayCollapsedHeightKey.self] = newValue }
    }
}
