//
//  DotSeparator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct DotSeparator: View {
    var size: CGFloat = 3

    var body: some View {
        Circle()
            .fill(DesignSystem.Color.iconSecondary)
            .frame(width: size, height: size)
    }
}
