//
//  OrganizeTokensCornerRadiusAnimatableModifier.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct OrganizeTokensCornerRadiusAnimatableModifier: AnimatableModifier {
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    private var progress: Double
    private let cornerRadius: CGFloat
    private let offset: CGFloat
    private let scale: CGFloat

    init(
        progress: Double,
        cornerRadius: CGFloat,
        offset: CGFloat,
        scale: CGFloat
    ) {
        self.progress = progress
        self.cornerRadius = cornerRadius
        self.offset = offset
        self.scale = scale
    }

    func body(content: Content) -> some View {
        return content
            .clipShape(
                // Ok, a tricky part here: clip shape is a drawing-only (layout-neutral) modifier,
                // but it can be applied to the `content` view, which already has been modified by
                // the other drawing-only (layout-neutral) modifiers like `Offset`, `Scale`, etc.
                //
                // Therefore, we should replicate these modifications for the clip shape in order to
                // match the final appearance of `content` view and clip shape.
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .scale(scale)
                    .offset(y: offset)
            )
    }
}
