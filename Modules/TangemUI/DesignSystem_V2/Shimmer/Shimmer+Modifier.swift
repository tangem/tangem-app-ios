//
//  Shimmer+Modifier.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    func tangemShimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

private struct ShimmerModifier: ViewModifier {
    @Environment(\.isShimmerActive) private var isShimmerActive

    func body(content: Content) -> some View {
        if isShimmerActive {
            content
                .mask { ShimmerShine() }
                .drawingGroup()
        } else {
            content
        }
    }
}
