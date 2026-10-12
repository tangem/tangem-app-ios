//
//  StatusScreen+Properties.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

/// An optional button rendered above the pinned one, in the secondary style.
public struct StatusScreenSecondaryAction {
    let title: String
    let action: () -> Void

    public init(title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }
}

public enum StatusScreenAppearance: Sendable, Hashable, CaseIterable {
    case neutral
    case success
    case error
    case warning
    case info
}

extension StatusScreenAppearance {
    var glowRingAppearance: GlowRingAppearance {
        switch self {
        case .neutral: .magic
        case .success: .success
        case .error: .error
        case .warning: .warning
        case .info: .info
        }
    }

    var iconGlyph: StatusIcon.Glyph {
        switch self {
        // The Figma Neutral variant reuses the Info glyph together with its status tint.
        case .neutral, .info: .info
        case .success: .checkmark
        case .error: .heartBroken
        case .warning: .warning
        }
    }

    /// Background circle tints come from the Figma `palette/*/70` and `palette/*/40`
    /// primitives, which the DS-Core token generator does not expose — only semantic
    /// tokens are generated. Values are theme-independent by design.
    var backgroundPalette: StatusScreenBackgroundPalette {
        switch self {
        case .neutral:
            StatusScreenBackgroundPalette(dimCircle: Color(hex: "#4A4A4A", fallback: .gray), accentCircle: Color(hex: "#989898", fallback: .gray))
        case .success:
            StatusScreenBackgroundPalette(dimCircle: Color(hex: "#1E6110", fallback: .green), accentCircle: Color(hex: "#2DAE3B", fallback: .green))
        case .error:
            StatusScreenBackgroundPalette(dimCircle: Color(hex: "#9E2729", fallback: .red), accentCircle: Color(hex: "#FF5E66", fallback: .red))
        case .warning:
            StatusScreenBackgroundPalette(dimCircle: Color(hex: "#965001", fallback: .orange), accentCircle: Color(hex: "#EFA210", fallback: .orange))
        case .info:
            StatusScreenBackgroundPalette(dimCircle: Color(hex: "#0C58AF", fallback: .blue), accentCircle: Color(hex: "#109FF0", fallback: .blue))
        }
    }
}

struct StatusScreenBackgroundPalette {
    let dimCircle: Color
    let accentCircle: Color
}
