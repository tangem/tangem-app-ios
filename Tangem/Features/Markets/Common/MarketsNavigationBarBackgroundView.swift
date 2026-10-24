//
//  MarketsNavigationBarBackgroundView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct MarketsNavigationBarBackgroundView<Overlay>: View where Overlay: View {
    let isListContentObscured: Bool
    @ViewBuilder var overlay: Overlay

    var body: some View {
        ZStack {
            // Translucent navigation bar background, visible when list content is obscured by the navigation bar/overlay
            Rectangle()
                .fill(.bar)
                .visible(isListContentObscured)
                .overlay(alignment: .bottom) {
                    overlay
                }
                .overlay(alignment: .bottom) {
                    listOverlaySeparator
                }
        }
        .background {
            // This invisible background view prevents touches from passing through the `MarketsNavigationBarBackgroundView`
            // when it is hidden or has zero opacity/clear color
            SwiftUITouchPassthroughView { _, _ in false }
        }
    }

    private var listOverlaySeparator: some View {
        Separator(height: .minimal, color: DesignSystem.Color.borderSecondary)
            .visible(isListContentObscured)
    }
}

// MARK: - Convenience extensions

extension MarketsNavigationBarBackgroundView where Overlay == EmptyView {
    init(isListContentObscured: Bool) {
        self.init(isListContentObscured: isListContentObscured) {
            EmptyView()
        }
    }
}
