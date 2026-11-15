//
//  ActionMessage+Style.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

extension ActionMessage {
    struct Style: ButtonStyle {
        let background: Color

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .background {
                    Capsule()
                        .fill(background)
                        .overlay {
                            Capsule()
                                .fill(DesignSystem.Color.interactionPressDefault)
                                .opacity(configuration.isPressed ? 1 : 0)
                                .animation(Animations.press, value: configuration.isPressed)
                        }
                }
                .contentShape(Capsule())
        }
    }
}

// MARK: - Constants

private extension ActionMessage.Style {
    enum Animations {
        static let press: Animation = .timingCurve(0.8, 0, 0.6, 1, duration: 0.2)
    }
}
