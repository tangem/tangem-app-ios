//
//  TangemPayCardClosingMessageView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUIUtils

struct TangemPayCardClosingMessageView: View {
    var body: some View {
        VStack(spacing: 12) {
            DesignSystem.Icons.Clock.regular20.image
                .renderingMode(.template)
                .foregroundStyle(DesignSystem.Color.iconSecondary)
                .frame(size: .init(bothDimensions: 40))
                .background(DesignSystem.Color.bgOpaquePrimary)
                .clipShape(Circle())

            VStack(spacing: 4) {
                Text(Localization.tangempayCardPageClosingBannerTitle)
                Text(Localization.tangempayCardPageClosingBannerDescription)
            }
            .font(token: DesignSystem.Font.captionMediumToken)
            .foregroundStyle(DesignSystem.Color.textSecondary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 48)
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    TangemPayCardClosingMessageView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Color.bgPrimary)
}
#endif // DEBUG
