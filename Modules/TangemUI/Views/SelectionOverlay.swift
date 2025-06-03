//
//  SelectionOverlay.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

/// The blue overlay
public struct SelectionOverlay: View {
    public init() {}

    public var body: some View {
        Color.clear.overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Colors.Icon.accent, lineWidth: 1)
        }
        .padding(1)
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Colors.Icon.accent.opacity(0.15), lineWidth: 2.5)
        }
        .padding(2.5)
    }
}
