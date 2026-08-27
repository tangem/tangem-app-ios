//
//  WithdrawHubActionTileView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct WithdrawHubActionTileView: View {
    let icon: ImageType
    let title: String
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        SwiftUI.Button(action: action) {
            VStack(alignment: .leading, spacing: 40) {
                icon.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: Constants.iconSide, height: Constants.iconSide)
                    .foregroundStyle(DesignSystem.Color.iconStaticDark)
                    .frame(width: Constants.iconBackgroundSide, height: Constants.iconBackgroundSide)
                    .background(DesignSystem.Color.bgStatusInfo, in: Circle())

                Text(title)
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
                    .multilineTextAlignment(.leading)
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

private extension WithdrawHubActionTileView {
    enum Constants {
        static let tileSide: CGFloat = 150
        static let tilePadding: CGFloat = 16
        static let cornerRadius: CGFloat = 20

        static let iconSide: CGFloat = 20
        static let iconBackgroundSide: CGFloat = 32
    }
}

// MARK: - Previews

#Preview {
    WithdrawHubActionTileView(
        icon: DesignSystem.Icons.ArrowSwapHorizontal.regular20,
        title: "Within your portfolio",
        action: {}
    )
    .frame(width: 156, height: 136)
}
