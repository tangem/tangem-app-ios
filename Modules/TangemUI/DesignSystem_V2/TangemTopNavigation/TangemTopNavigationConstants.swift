//
//  TangemTopNavigationConstants.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

// MARK: - Content alignment

extension EnvironmentValues {
    @Entry var tangemTopNavigationContentAlignment: HorizontalAlignment = .center
}

// MARK: - Constants

enum TangemTopNavigationConstants {
    static let titleSubtitleSpacing: CGFloat = 4
    static let maxActionCount = 3
    static let barChipSize: TangemButtonV2.Size = .x9
}
