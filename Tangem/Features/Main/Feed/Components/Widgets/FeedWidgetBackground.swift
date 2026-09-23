//
//  FeedWidgetBackground.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct FeedWidgetBackground: View {
    let defaultColor: Color

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if colorScheme == .light {
            DesignSystem.Color.bgSecondary
        } else {
            defaultColor
        }
    }
}
