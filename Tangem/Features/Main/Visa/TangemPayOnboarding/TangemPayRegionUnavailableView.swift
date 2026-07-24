//
//  TangemPayRegionUnavailableView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils
import TangemLocalization

struct TangemPayRegionUnavailableView: View {
    let onGotIt: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                DesignSystem.Icons.HeartBroken.regular32.image
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .foregroundStyle(DesignSystem.Color.iconPrimary)

                VStack(alignment: .leading, spacing: 12) {
                    Text(Localization.tangemPayUnavailableRegionTitle)
                        .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)

                    Text(Localization.tangemPayUnavailableRegionDescription)
                        .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                }
                .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 12)

            Spacer()

            TangemButtonV2(
                label: AttributedString(Localization.commonGotIt),
                accessibilityLabel: Localization.commonGotIt,
                action: onGotIt
            )
            .size(.x12)
            .styleType(.default)
            .horizontalLayout(.infinity)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
    }
}

// MARK: - Previews

#Preview {
    TangemPayRegionUnavailableView(onGotIt: {})
}
