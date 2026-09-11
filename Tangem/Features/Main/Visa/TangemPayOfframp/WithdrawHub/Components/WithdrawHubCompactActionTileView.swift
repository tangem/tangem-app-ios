//
//  WithdrawHubCompactActionTileView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct WithdrawHubCompactActionTileView: View {
    let icon: ImageType
    let title: String
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        SwiftUI.Button(action: action) {
            HStack(spacing: 12) {
                icon.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: Constants.iconSide, height: Constants.iconSide)
                    .foregroundStyle(DesignSystem.Color.iconStaticDark)
                    .frame(width: Constants.iconBackgroundSide, height: Constants.iconBackgroundSide)
                    .background(DesignSystem.Color.bgStatusInfo, in: Circle())

                Text(title)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Constants.tilePadding)
            .background(
                DesignSystem.Color.bgStatusInfoSubtle,
                in: RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous)
            )
            .opacity(isEnabled ? 1 : 0.6)
        }
        .buttonStyle(.defaultScaled)
    }
}

// MARK: - Constants

private extension WithdrawHubCompactActionTileView {
    enum Constants {
        static let tilePadding: CGFloat = 16
        static let cornerRadius: CGFloat = 20

        static let iconSide: CGFloat = 16
        static let iconBackgroundSide: CGFloat = 32
    }
}

// MARK: - Previews

#Preview {
    WithdrawHubCompactActionTileView(
        icon: DesignSystem.Icons.User.regular16,
        title: "To personal account",
        action: {}
    )
    .frame(width: 156, height: 136)
}
