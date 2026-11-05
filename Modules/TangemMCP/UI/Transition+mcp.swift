//
//  Transition+mcp.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

extension AnyTransition {
    static var mcpContent: AnyTransition {
        AnyTransition.asymmetric(
            insertion: .opacity.animation(.curve(.easeInOutRefined, duration: 0.3).delay(0.2)),
            removal: .opacity.animation(.curve(.easeInOutRefined, duration: 0.3))
        )
    }
}
