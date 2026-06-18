//
//  TangemPayCardIssuingMessageView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization

struct TangemPayCardIssuingMessageView: View {
    var body: some View {
        VStack(spacing: 12) {
            DesignSystem.Icons.Clock.regular20.image
                .renderingMode(.template)
                .foregroundStyle(DesignSystem.Color.iconSecondary)
                .frame(width: 40, height: 40)
                .background(DesignSystem.Color.bgOpaquePrimary)
                .clipShape(Circle())

            VStack(spacing: 4) {
                Text(Localization.tangempayIssuingNewDigitalCardTitle)
                Text(Localization.tangempayReissueCardInProgressDescription)
            }
            .font(DesignSystem.Font.captionMediumToken)
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
    TangemPayCardIssuingMessageView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Color.bgPrimary)
}
#endif // DEBUG
