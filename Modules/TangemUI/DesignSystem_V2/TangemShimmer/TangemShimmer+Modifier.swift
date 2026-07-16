//
//  TangemShimmer+Modifier.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    func tangemShimmer() -> some View {
        modifier(TangemShimmerModifier())
    }
}

private struct TangemShimmerModifier: ViewModifier {
    @Environment(\.isShimmerActive) private var isShimmerActive

    func body(content: Content) -> some View {
        if isShimmerActive {
            content
                .mask { TangemShimmerShine() }
                .drawingGroup()
        } else {
            content
        }
    }
}
