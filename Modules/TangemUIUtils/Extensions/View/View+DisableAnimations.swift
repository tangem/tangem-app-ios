//
//  View+DisableAnimations.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    func disableAnimations() -> some View {
        transaction { transaction in
            transaction.animation = nil
        }
    }
}
