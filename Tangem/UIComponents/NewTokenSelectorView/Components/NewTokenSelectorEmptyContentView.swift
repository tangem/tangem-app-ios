//
//  NewTokenSelectorEmptyContentView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

struct NewTokenSelectorEmptyContentView: View {
    let message: String

    var body: some View {
        Text(message)
            .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
            .multilineTextAlignment(.center)
            .infinityFrame(axis: .horizontal)
            .defaultRoundedBackground(with: Colors.Background.action)
            .transition(.move(edge: .top).combined(with: .opacity).animation(.easeInOut))
    }
}
