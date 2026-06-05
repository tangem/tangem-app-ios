//
//  View+isRedesign.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    func redesigned() -> some View {
        environment(\.isRedesign, true)
    }
}

// [REDACTED_TODO_COMMENT]

extension EnvironmentValues {
    @Entry var isRedesign = false
}
