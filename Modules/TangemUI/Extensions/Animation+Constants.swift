//
//  Animation+Constants.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

public extension Animation {
    /// Mimics iOS default keyboard animation.
    /// - Note: almost identical.
    static let keyboard = Animation.interpolatingSpring(mass: 3, stiffness: 1000, damping: 500)
}
