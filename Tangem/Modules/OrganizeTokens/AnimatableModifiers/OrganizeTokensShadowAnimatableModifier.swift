//
//  OrganizeTokensShadowModifier.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct OrganizeTokensShadowAnimatableModifier: AnimatableModifier {
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    private var progress: Double

    private var shadowColor: Color {
        // [REDACTED_TODO_COMMENT]
        Color.black.opacity(0.08)
    }

    init(
        progress: Double
    ) {
        self.progress = progress
    }

    func body(content: Content) -> some View {
        return content
            .shadow(
                color: shadowColor.opacity(progress),
                radius: 14.0,
                y: 8.0
            )
    }
}
