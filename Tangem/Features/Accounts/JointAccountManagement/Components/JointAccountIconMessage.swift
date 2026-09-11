//
//  JointAccountIconMessage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct JointAccountIconMessage: View {
    let icon: ImageType
    let iconColor: Color
    let iconBackgroundColor: Color
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: Constants.iconSpacing) {
            iconView

            VStack(spacing: Constants.textSpacing) {
                Text(title)
                    .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Constants.textHorizontalPadding)
        }
    }

    private var iconView: some View {
        Circle()
            .fill(iconBackgroundColor)
            .frame(size: Constants.iconBackgroundSize)
            .overlay {
                icon.image
                    .renderingMode(.template)
                    .foregroundStyle(iconColor)
            }
    }
}

// MARK: - Constants

private extension JointAccountIconMessage {
    enum Constants {
        static let iconSpacing: CGFloat = 32
        static let textSpacing: CGFloat = 8
        static let textHorizontalPadding: CGFloat = 32
        static let iconBackgroundSize = CGSize(bothDimensions: 72)
    }
}

// MARK: - Previews

#Preview {
    JointAccountIconMessage(
        icon: DesignSystem.Icons.Warning.filled28,
        iconColor: DesignSystem.Color.iconStatusWarning,
        iconBackgroundColor: DesignSystem.Color.bgStatusWarningSubtle,
        title: "Invitation link isn't valid",
        message: "Check that you opened the full link, or ask the account owner to send it again."
    )
    .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
}
