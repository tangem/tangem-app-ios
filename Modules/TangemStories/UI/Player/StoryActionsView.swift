//
//  StoryActionsView.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct StoryActionsView: View {
    let actions: [StoryActionV2]
    let onTap: (StoryActionV2) -> Void

    var body: some View {
        if !actions.isEmpty {
            VStack(spacing: Layout.spacing) {
                ForEach(actions, id: \.id) { action in
                    TangemUI.Button(
                        label: action.label,
                        accessibilityLabel: nil,
                        action: { onTap(action) }
                    )
                    .iconEnd(action.icon)
                    .styleType(action.style == .primary ? .default : .secondary(.default))
                    .horizontalLayout(.infinity)
                    .size(.x14)
                }
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.bottom, Layout.bottomPadding)
        }
    }

    private enum Layout {
        static let spacing: CGFloat = 10
        static let horizontalPadding: CGFloat = 16
        static let bottomPadding: CGFloat = 20
    }
}
