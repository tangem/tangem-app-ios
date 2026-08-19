//
//  TangemPayCurrentPlanInfoBanner.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

/// It's not a part of design system so far. In future most likely can be replaced
struct TangemPayCurrentPlanInfoBanner: View {
    private let title: String
    private let button: TangemPayCurrentPlanInfoBannerButton?

    init(title: String, button: TangemPayCurrentPlanInfoBannerButton? = nil) {
        self.title = title
        self.button = button
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 8) {
                DesignSystem.Icons.Info.regular20.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(DesignSystem.Color.iconStatusInfo)

                Text(title)
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let button {
                TangemUI.Button(
                    label: AttributedString(button.title),
                    accessibilityLabel: button.title,
                    action: button.action
                )
                .size(.x8)
                .styleType(.secondary)
                .horizontalLayout(.infinity)
                .isLoading(button.isLoading)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 16)
        .background(DesignSystem.Color.bgStatusInfoSubtle)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct TangemPayCurrentPlanInfoBannerButton {
    let title: String
    var isLoading: Bool = false
    let action: () -> Void
}

// MARK: - Previews

#Preview {
    VStack(spacing: 24) {
        TangemPayCurrentPlanInfoBanner(title: "Plus is active till Sep 1, then you move to Basic for $0")

        TangemPayCurrentPlanInfoBanner(
            title: "We are in process of moving you to Plus plan and awaiting payment for plan fee",
            button: TangemPayCurrentPlanInfoBannerButton(title: "Cancel Plus, move to Basic", action: {})
        )
    }
    .padding(.horizontal, 16)
}
