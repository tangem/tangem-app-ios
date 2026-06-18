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
        VStack(spacing: DesignSystem.Tokens.Spacing.s150) {
            DesignSystem.Icons.Clock.regular20.image
                .renderingMode(.template)
                .foregroundStyle(DesignSystem.Tokens.Theme.Icon.secondary)
                .frame(width: DesignSystem.Tokens.Size.s500, height: DesignSystem.Tokens.Size.s500)
                .background(DesignSystem.Tokens.Theme.Bg.Opaque.primary)
                .clipShape(Circle())

            VStack(spacing: DesignSystem.Tokens.Spacing.s050) {
                Text(Localization.tangempayIssuingNewDigitalCardTitle)
                Text(Localization.tangempayReissueCardInProgressDescription)
            }
            .font(DesignSystem.Tokens.Font.Caption.medium)
            .foregroundStyle(DesignSystem.Tokens.Theme.Text.secondary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, DesignSystem.Tokens.Spacing.s600)
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    TangemPayCardIssuingMessageView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Tokens.Theme.Bg.primary)
}
#endif // DEBUG
