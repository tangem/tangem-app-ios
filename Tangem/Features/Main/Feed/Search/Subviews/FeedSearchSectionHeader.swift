//
//  FeedSearchSectionHeader.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct FeedSearchSectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Text(title)
                .lineLimit(1)
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)

            Spacer(minLength: Constants.titleSpacing)

            actionButton
        }
        .frame(minHeight: Constants.minHeight)
    }

    @ViewBuilder
    private var actionButton: some View {
        if let actionTitle, let action {
            TangemUI.Button(label: actionTitle, accessibilityLabel: actionTitle, action: action)
                .styleType(.ghost)
                .size(.x9)
        }
    }
}

// MARK: - Constants

private extension FeedSearchSectionHeader {
    enum Constants {
        static let titleSpacing: CGFloat = 8
        static let minHeight = TangemUI.Button.Size.x9.height
    }
}
