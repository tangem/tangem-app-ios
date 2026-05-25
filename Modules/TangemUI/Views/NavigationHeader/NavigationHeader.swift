//
//  NavigationHeader.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import BlurSwiftUI
import TangemAssets

public struct NavigationHeader<L: View, P: View, T: View>: View {
    private let leadingContent: L
    private let principalContent: P
    private let trailingContent: T

    public init(
        @ViewBuilder leadingContent: () -> L,
        @ViewBuilder principalContent: () -> P,
        @ViewBuilder trailingContent: () -> T
    ) {
        self.leadingContent = leadingContent()
        self.principalContent = principalContent()
        self.trailingContent = trailingContent()
    }

    public var body: some View {
        HStack(spacing: 0) {
            leadingContent
            Spacer(minLength: SizeUnit.x2.value)
            trailingContent
        }
        .overlay(alignment: .center) {
            principalContent
        }
        .padding(.horizontal, .unit(.x4))
        .padding(.top, .unit(.x4))
        .padding(.bottom, .unit(.x3))
        .background(alignment: .top) {
            VariableBlur(direction: .down)
                .dimmingAlpha(.constant(alpha: 0.5))
                .dimmingOvershoot(nil)
                .ignoresSafeArea()
        }
    }
}
