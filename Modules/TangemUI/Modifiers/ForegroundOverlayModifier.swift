//
//  ForegroundOverlayModifier.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct ForegroundOverlayModifier<S: ShapeStyle>: ViewModifier {
    let style: S

    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(style)
                    .mask(content)
            )
    }
}
