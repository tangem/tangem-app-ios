//
//  TangemCallout+Properties.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

// MARK: - Properties

public extension TangemCallout {
    enum ArrowAlignment {
        case top
        case bottom
    }

    enum CalloutColor {
        case green
        case gray
    }

    struct Action {
        let icon: Image
        let closure: () -> Void
    }
}
