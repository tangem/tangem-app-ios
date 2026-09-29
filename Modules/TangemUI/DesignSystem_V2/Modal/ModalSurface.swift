//
//  ModalSurface.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import BlurSwiftUI

struct ModalBackgroundModifier: ViewModifier {
    let size: ModalSize

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
        } else {
            content.presentationBackground {
                ModalSurface(isExpanded: size == .full)
            }
        }
    }
}

struct ModalSurface: View {
    let isExpanded: Bool

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        surface
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }

    @ViewBuilder
    private var surface: some View {
        if isExpanded {
            DesignSystem.Color.bgPrimary
        } else if reduceTransparency {
            DesignSystem.Color.materialModalFillSolid
        } else {
            VariableBlur(direction: .down)
                .maximumBlurRadius(32)
                .dimmingTintColor(nil)
                .dimmingAlpha(.constant(alpha: 0))
                .dimmingOvershoot(nil)
                .overlay { DesignSystem.Color.materialModalFillBlur }
        }
    }
}
