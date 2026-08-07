//
//  AddressBooksUpdateRequiredView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct AddressBooksUpdateRequiredView: View {
    let onUpdateTap: () -> Void

    @ScaledMetric private var iconContainerSize: CGFloat = 80
    @ScaledMetric private var iconSize: CGFloat = 28

    var body: some View {
        VStack(spacing: 32) {
            icon

            VStack(spacing: 8) {
                Text(Localization.forceUpdateWarningTitle)
                    .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
                    .multilineTextAlignment(.center)

                Text(Localization.forceUpdateWarningMessage)
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 16)
        }
        .infinityFrame()
        .padding(.horizontal, 30)
        .safeAreaInset(edge: .bottom) {
            updateButton
        }
    }

    private var icon: some View {
        DesignSystem.Color.bgStatusInfoSubtle
            .frame(width: iconContainerSize, height: iconContainerSize)
            .overlay {
                DesignSystem.Icons.Info.regular28.image
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: iconSize, height: iconSize)
                    .foregroundColor(DesignSystem.Color.iconBrand)
            }
            .clipShape(Circle())
    }

    private var updateButton: some View {
        TangemButtonV2(
            label: AttributedString(Localization.forceUpdateRequiredAction),
            accessibilityLabel: Localization.forceUpdateRequiredAction,
            action: onUpdateTap
        )
        .styleType(.default)
        .size(.x12)
        .horizontalLayout(.infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// MARK: - Previews

#Preview {
    AddressBooksUpdateRequiredView(onUpdateTap: {})
        .background(DesignSystem.Color.bgBase.edgesIgnoringSafeArea(.all))
}
