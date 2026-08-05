//
//  View+dimmed.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    /// Renders a supporting view in its unavailable appearance while keeping it interactive,
    /// so a tap can explain why the action is unavailable instead of being swallowed.
    func dimmed(_ isDimmed: Bool = true) -> some View {
        environment(\.isDimmed, isDimmed)
    }
}

public extension EnvironmentValues {
    @Entry var isDimmed = false
}
