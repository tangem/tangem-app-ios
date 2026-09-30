//
//  StoryTitleView.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct StoryTitleView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                .lineLimit(3)

            Text(subtitle)
                .style(Fonts.Regular.callout, color: Colors.Text.secondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
        .allowsHitTesting(false)
    }
}
